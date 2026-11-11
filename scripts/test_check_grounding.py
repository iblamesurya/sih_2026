import sys
from google.cloud import discoveryengine_v1alpha as discoveryengine

def test_check_grounding():
    project_id = "elite-magpie-460716-s7"
    client = discoveryengine.GroundedGenerationServiceClient()

    grounding_config = f"projects/{project_id}/locations/global/groundingConfigs/default_grounding_config"
    candidate = "Potassium permanganate should be applied at 2 to 4 ppm for water disinfection."
    facts = [
        discoveryengine.GroundingFact(
            fact_text="Potassium Permanganate dosage for shrimp pond disinfection is 2-4 ppm (2-4 kg per hectare-meter water depth)."
        ),
        discoveryengine.GroundingFact(
            fact_text="Dissolved Oxygen (DO) must be maintained above 4.5 ppm at all times in Vannamei culture."
        )
    ]

    request = discoveryengine.CheckGroundingRequest(
        grounding_config=grounding_config,
        answer_candidate=candidate,
        facts=facts,
    )

    try:
        print(f"Calling check_grounding on {grounding_config}...")
        response = client.check_grounding(request=request)
        print("Success! Grounding response:")
        print(response)
    except Exception as e:
        print(f"API result/error:\n{e}")

if __name__ == "__main__":
    test_check_grounding()
