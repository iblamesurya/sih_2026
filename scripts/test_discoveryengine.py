import os
from google.cloud import discoveryengine_v1alpha as discoveryengine

def test_discovery_engine():
    project_id = "elite-magpie-460716-s7"
    client = discoveryengine.GroundedGenerationServiceClient()
    
    inline_facts = [
        discoveryengine.GroundingFact(
            fact_text="Potassium Permanganate dosage for shrimp pond disinfection is 2-4 ppm (2-4 kg per hectare-meter water depth)."
        ),
        discoveryengine.GroundingFact(
            fact_text="Dissolved Oxygen (DO) must be maintained above 4.5 ppm at all times in Vannamei culture."
        )
    ]

    request = discoveryengine.GenerateGroundedContentRequest(
        location=f"projects/{project_id}/locations/global",
        system_instruction=discoveryengine.GenerateGroundedContentRequest.Content(
            parts=[discoveryengine.GenerateGroundedContentRequest.Content.Part(
                text="You are AquaVerse AI veterinary advisor. Answer concisely based strictly on provided facts."
            )]
        ),
        contents=[
            discoveryengine.GenerateGroundedContentRequest.Content(
                role="user",
                parts=[discoveryengine.GenerateGroundedContentRequest.Content.Part(
                    text="What is the recommended dosage of Potassium Permanganate for a 1 hectare-meter pond?"
                )]
            )
        ],
        generation_spec=discoveryengine.GenerateGroundedContentRequest.GenerationSpec(
            model_id="default"
        ),
        grounding_spec=discoveryengine.GenerateGroundedContentRequest.GroundingSpec(
            grounding_sources=[
                discoveryengine.GenerateGroundedContentRequest.GroundingSource(
                    inline_source=discoveryengine.GenerateGroundedContentRequest.GroundingSource.InlineSource(
                        grounding_facts=inline_facts
                    )
                )
            ]
        )
    )

    try:
        print(f"Calling Discovery Engine for project {project_id}...")
        response = client.generate_grounded_content(request)
        print("Success! Response from Discovery Engine:")
        print(response.candidates[0].content.parts[0].text)
    except Exception as e:
        print(f"Caught expected API/Billing exception:\n{e}")

if __name__ == "__main__":
    test_discovery_engine()
