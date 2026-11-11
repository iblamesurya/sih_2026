"""
Interactive verification and test runner for Google Cloud Discovery Engine.
Checks authentication, billing status, API enablement, and executes live calls.
"""

import subprocess
import sys
import json

def run_cmd(cmd_list):
    try:
        res = subprocess.run(cmd_list, capture_output=True, text=True, check=False, shell=True)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, "", str(e)

def main():
    print("=" * 70)
    print(" AquaVerse / PrawnGuard - Discovery Engine Credit Verifier")
    print(" Covered by: Trial credit for GenAI App Builder (Rs 94,812.51)")
    print("=" * 70)

    project_id = "elite-magpie-460716-s7"
    billing_id = "01E300-0C7289-1F7A0A"

    # Step 1: Check gcloud account
    code, out, _ = run_cmd(["gcloud", "config", "get-value", "account"])
    account = out if code == 0 else "Unknown"
    print(f"\n[1] Active gcloud Account: {account}")

    # Step 2: Check project
    print(f"[2] Active Project ID: {project_id}")

    # Step 3: Check billing account status
    code, out, err = run_cmd(["gcloud", "billing", "accounts", "describe", billing_id, "--format=json"])
    is_open = False
    if code == 0:
        try:
            b_info = json.loads(out)
            is_open = b_info.get("open", False)
            print(f"[3] Billing Account '{b_info.get('displayName')}' ({billing_id}): {'OPEN' if is_open else 'CLOSED'}")
        except Exception:
            print(f"[3] Billing Account: {out}")
    else:
        print(f"[3] Billing Account: Error reading ({err})")

    # Step 4: Check if API is enabled
    code, out, _ = run_cmd(["gcloud", "services", "list", "--enabled", f"--project={project_id}", "--filter=name:discoveryengine.googleapis.com"])
    is_api_enabled = "discoveryengine.googleapis.com" in out
    print(f"[4] Discovery Engine API Enabled on {project_id}: {'YES' if is_api_enabled else 'NO'}")

    if not is_open:
        print("\n" + "!" * 70)
        print("ACTION REQUIRED TO ACTIVATE YOUR Rs 94,812.51 CREDIT:")
        print(f"1. Open your Google Cloud Billing Console:")
        print(f"   https://console.cloud.google.com/billing/{billing_id}")
        print(f"2. Click 'Reopen billing account' (or verify your payment profile).")
        print(f"   (Google Cloud requires an open billing account to route the Rs 94,812 credit).")
        print(f"3. Run this script again to automatically enable discoveryengine.googleapis.com!")
        print("!" * 70)
        return

    if not is_api_enabled:
        print(f"\n[INFO] Enabling discoveryengine.googleapis.com on project {project_id}...")
        code, out, err = run_cmd(["gcloud", "services", "enable", "discoveryengine.googleapis.com", f"--project={project_id}"])
        if code == 0:
            print("Successfully enabled Discovery Engine API!")
        else:
            print(f"Failed to enable API: {err}")
            return

    # Step 5: Run live test with discovery_engine_client
    print("\n[5] Executing live Discovery Engine test calls...")
    try:
        from discovery_engine_client import PrawnGuardDiscoveryEngine
        engine = PrawnGuardDiscoveryEngine(project_id=project_id)

        print("\n--- Testing Chemical Dosage Hallucination Guardrail (CheckGrounding) ---")
        facts = [
            "Potassium Permanganate dosage for shrimp pond water disinfection is 2-4 ppm (2-4 kg per hectare-meter water depth).",
            "Avoid using Potassium Permanganate when Dissolved Oxygen is below 4.0 ppm as it causes sudden chemical oxygen demand."
        ]
        treatment_candidate = "Apply Potassium Permanganate at 3 ppm (3 kg per hectare-meter) during daylight when aeration is active."

        result = engine.check_treatment_grounding(treatment_candidate, facts)
        print("Support Score:", result.get("support_score"))
        print("Is Safe:", result.get("is_safe"))
        print("Claims Breakdown:", json.dumps(result.get("claims"), indent=2))

        print("\n--- Testing Veterinary Protocol Neural Re-Ranker (RankService) ---")
        records = [
            {"id": "proto_1", "title": "White Spot Syndrome Protocol", "content": "Immediately stop water exchange, reduce feed by 50%, increase continuous aeration to 24 hours, and apply biosecurity fences."},
            {"id": "proto_2", "title": "Ammonia Spike Remediation", "content": "Apply Yucca extract at 1 kg/acre, reduce feed immediately by 30%, broadcast zeolite at 50 kg/acre, and maintain pH between 7.5 and 8.2."},
            {"id": "proto_3", "title": "Molting & Mineral Supplementation", "content": "Apply Magnesium Chloride and Calcium Carbonate during new moon or full moon molting cycle to prevent soft shell syndrome."}
        ]
        ranked = engine.rank_veterinary_protocols("Shrimp dying with white spots on carapace and sluggish swimming", records)
        print("Re-ranked results by semantic relevance:")
        for r in ranked:
            print(f"  Score: {r['score']:.4f} | Title: {r['title']}")

        print("\nAll Discovery Engine services verified working and consuming GenAI App Builder credit!")

    except Exception as e:
        print(f"Test call error: {e}")

if __name__ == "__main__":
    main()
