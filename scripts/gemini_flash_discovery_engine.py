"""
AquaVerse / PrawnGuard - Gemini Flash via Discovery Engine
Demonstrates how to invoke Gemini Flash models (stable/preview) under the
GenAI App Builder credit (₹94,812.51) without incurring charges on your card.
"""

from google.cloud import discoveryengine_v1alpha as discoveryengine

PROJECT_ID = "elite-magpie-460716-s7"
LOCATION = "global"

def query_gemini_flash_answer(
    data_store_id: str,
    question: str,
    system_instruction: str = "You are an expert aquaculture AI veterinary scientist.",
    model_version: str = "stable"  # "stable" maps to gemini-3.5-flash/answer_gen/v1, or "preview"
):
    """
    Invokes Gemini Flash to generate an answer over an indexed Data Store.
    Consumes GenAI App Builder credit (~$4 to $8 per 1,000 queries).
    """
    client = discoveryengine.ConversationalSearchServiceClient()
    serving_config = (
        f"projects/{PROJECT_ID}/locations/{LOCATION}/"
        f"collections/default_collection/dataStores/{data_store_id}/"
        f"servingConfigs/default_serving_config"
    )

    # Configure Gemini Flash model version and prompt instructions
    generation_spec = discoveryengine.AnswerQueryRequest.AnswerGenerationSpec(
        model_spec=discoveryengine.AnswerQueryRequest.AnswerGenerationSpec.ModelSpec(
            model_version=model_version
        ),
        prompt_spec=discoveryengine.AnswerQueryRequest.AnswerGenerationSpec.PromptSpec(
            preamble=system_instruction
        ),
        include_citations=True,
        answer_language_code="en"  # Supports "te" (Telugu), "hi" (Hindi), etc.
    )

    request = discoveryengine.AnswerQueryRequest(
        serving_config=serving_config,
        query=discoveryengine.Query(text=question),
        answer_generation_spec=generation_spec
    )

    response = client.answer_query(request=request)
    return {
        "answer": response.answer.answer_text,
        "query_token": response.answer_query_token,
    }

def multi_turn_chat_with_gemini(
    conversation_id: str,
    user_message: str,
    data_store_id: str
):
    """
    Conducts multi-turn conversational chat with Gemini Flash with session memory.
    """
    client = discoveryengine.ConversationalSearchServiceClient()
    serving_config = (
        f"projects/{PROJECT_ID}/locations/{LOCATION}/"
        f"collections/default_collection/dataStores/{data_store_id}/"
        f"servingConfigs/default_serving_config"
    )

    request = discoveryengine.ConverseConversationRequest(
        name=f"{serving_config}/conversations/{conversation_id}",
        query=discoveryengine.TextInput(input=user_message),
    )

    response = client.converse_conversation(request=request)
    return response.reply.reply

if __name__ == "__main__":
    print("Gemini Flash Discovery Engine Integration Ready.")
    print("Default Model Version: Gemini Flash (stable / preview)")
