"""
AquaVerse (PrawnGuard) Discovery Engine / GenAI App Builder Integration.
Consumes Google Cloud Discovery Engine promotional credit (₹94,812.51 / $1,000 USD).

APIs implemented:
1. Hallucination Check / Safety Guardrail (GroundedGenerationService.CheckGrounding)
2. Neural Semantic Re-Ranker (RankService.Rank)
3. Conversational RAG & Answer Generation (ConversationalSearchService.AnswerQuery)
"""

import sys
import json
import time
import random
import logging
from typing import List, Dict, Any, Optional, Callable
from google.cloud import discoveryengine_v1alpha as discoveryengine
from google.api_core import exceptions as gexceptions

logger = logging.getLogger(__name__)

DEFAULT_PROJECT_ID = "elite-magpie-460716-s7"
DEFAULT_LOCATION = "global"

def retry_with_exponential_backoff(
    func: Callable,
    max_retries: int = 3,
    initial_delay: float = 1.0,
    backoff_factor: float = 2.0,
    jitter: bool = True
) -> Any:
    """
    Executes a callable with exponential backoff and jitter for transient API errors
    (ResourceExhausted 429, ServiceUnavailable 503, DeadlineExceeded 504).
    """
    delay = initial_delay
    last_exception = None

    for attempt in range(1, max_retries + 1):
        try:
            return func()
        except (gexceptions.ResourceExhausted, gexceptions.ServiceUnavailable, gexceptions.DeadlineExceeded, ConnectionError) as exc:
            last_exception = exc
            if attempt == max_retries:
                logger.error(f"Discovery Engine API call failed after {max_retries} attempts: {exc}")
                raise
            sleep_time = delay * (1 + (random.random() * 0.2 if jitter else 0))
            logger.warning(f"Transient error ({exc.__class__.__name__}), retrying in {sleep_time:.2f}s (attempt {attempt}/{max_retries})...")
            time.sleep(sleep_time)
            delay *= backoff_factor
        except Exception as exc:
            # Fatal / non-retryable exception
            logger.error(f"Discovery Engine non-retryable exception: {exc}")
            raise

    raise last_exception

class PrawnGuardDiscoveryEngine:
    def __init__(self, project_id: str = DEFAULT_PROJECT_ID, location: str = DEFAULT_LOCATION):
        self.project_id = project_id
        self.location = location
        self._grounding_client = None
        self._rank_client = None
        self._conversational_client = None

    @property
    def grounding_client(self) -> discoveryengine.GroundedGenerationServiceClient:
        if self._grounding_client is None:
            self._grounding_client = discoveryengine.GroundedGenerationServiceClient()
        return self._grounding_client

    @property
    def rank_client(self) -> discoveryengine.RankServiceClient:
        if self._rank_client is None:
            self._rank_client = discoveryengine.RankServiceClient()
        return self._rank_client

    @property
    def conversational_client(self) -> discoveryengine.ConversationalSearchServiceClient:
        if self._conversational_client is None:
            self._conversational_client = discoveryengine.ConversationalSearchServiceClient()
        return self._conversational_client

    def check_treatment_grounding(
        self,
        candidate_treatment: str,
        reference_facts: List[str],
        grounding_config: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Validates LLM-generated chemical treatment dosages against official aquaculture manuals
        (CIBA / MPEDA / CAA protocols) to prevent fatal overdosing in shrimp ponds.
        
        Billed strictly to Discovery Engine CheckGrounding SKU.
        """
        if not grounding_config:
            grounding_config = (
                f"projects/{self.project_id}/locations/{self.location}/"
                f"groundingConfigs/default_grounding_config"
            )

        facts = [discoveryengine.GroundingFact(fact_text=f) for f in reference_facts]
        request = discoveryengine.CheckGroundingRequest(
            grounding_config=grounding_config,
            answer_candidate=candidate_treatment,
            facts=facts,
        )

        response = retry_with_exponential_backoff(lambda: self.grounding_client.check_grounding(request=request))
        claims = []
        for claim in response.claims:
            claims.append({
                "claim_text": claim.claim_text,
                "start_pos": claim.start_pos,
                "end_pos": claim.end_pos,
                "citation_indices": list(claim.citation_indices),
                "grounding_check_required": claim.grounding_check_required,
            })

        return {
            "support_score": response.support_score,
            "is_safe": (response.support_score is not None and response.support_score >= 0.8),
            "claims": claims,
        }

    def rank_veterinary_protocols(
        self,
        query: str,
        records: List[Dict[str, str]],
        top_n: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Cross-encoder semantic re-ranking for veterinary treatment sheets and farmer advisories.
        Takes candidate documents from local cache or database and scores them by relevance.
        
        Billed to Discovery Engine RankService SKU (~$1.00 per 1,000 calls).
        """
        ranking_config = (
            f"projects/{self.project_id}/locations/{self.location}/"
            f"rankingConfigs/default_ranking_config"
        )

        ranking_records = [
            discoveryengine.RankingRecord(
                id=rec.get("id", str(idx)),
                title=rec.get("title", ""),
                content=rec.get("content", "")
            )
            for idx, rec in enumerate(records)
        ]

        request = discoveryengine.RankRequest(
            ranking_config=ranking_config,
            query=query,
            records=ranking_records,
            top_n=top_n
        )

        response = retry_with_exponential_backoff(lambda: self.rank_client.rank(request=request))
        ranked_results = []
        for r in response.records:
            ranked_results.append({
                "id": r.id,
                "score": r.score,
                "title": r.title,
                "content": r.content
            })
        return ranked_results

    def answer_query_from_datastore(
        self,
        data_store_id: str,
        question: str,
        query_preamble: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Queries an indexed aquaculture PDF Data Store (e.g., shrimp-disease-manuals)
        and generates a cited response using Gemini.
        
        Billed to Discovery Engine ConversationalSearchService SKU.
        """
        serving_config = (
            f"projects/{self.project_id}/locations/{self.location}/"
            f"collections/default_collection/dataStores/{data_store_id}/"
            f"servingConfigs/default_serving_config"
        )

        query = discoveryengine.Query(text=question)
        answer_generation_spec = discoveryengine.AnswerQueryRequest.AnswerGenerationSpec()
        if query_preamble:
            answer_generation_spec.prompt_spec.preamble = query_preamble

        request = discoveryengine.AnswerQueryRequest(
            serving_config=serving_config,
            query=query,
            answer_generation_spec=answer_generation_spec,
        )

        response = retry_with_exponential_backoff(lambda: self.conversational_client.answer_query(request=request))
        citations = []
        for step in response.answer.steps:
            for citation in step.actions:
                citations.append(citation.description)

        return {
            "answer_text": response.answer.answer_text,
            "citations": citations,
            "query_id": response.answer_query_token,
        }

if __name__ == "__main__":
    print("AquaVerse Discovery Engine Module Initialized.")
    print("Target Project:", DEFAULT_PROJECT_ID)
