# Google Play Console: Data Safety Form & App Access Architecture

**Platform:** Google Play Console  
**Application:** PrawnGuard.ai (AquaVerse)  
**Target Package:** `com.aquaverse.prawnguard`  
**Compliance Baseline:** Google Play Developer Policy (Data Safety & User Data Privacy)  

---

## Part 1: Play Console Data Safety Questionnaire — Exact Answers

Navigate in Google Play Console to:  
**Policy and programs > App content > Data safety > Start**.

### 1. Data Collection and Security
* **Does your app collect or share any of the required user data types?**  
  👉 **Yes**
* **Is all of the user data collected by your app encrypted in transit?**  
  👉 **Yes** *(All communication uses TLS 1.3 / HTTPS; unencrypted connections are blocked)*
* **Do you provide a way for users to request that their data is deleted?**  
  👉 **Yes** *(In-app path: More > Profile Settings > Delete Account & Farm Data; URL: `https://prawnguard.ai/account-deletion`)*

---

### 2. Data Categories & Detailed Declarations

#### A. Location
1. **Approximate Location (`ACCESS_COARSE_LOCATION`)**
   - **Collected?** Yes
   - **Shared?** No (0 third-party sharing)
   - **Processed ephemerally?** No (Saved to farm profile for weather telemetry)
   - **Required or Optional?** **Optional** (Farmers can manually pick their district/hub if location is denied)
   - **Purposes:** **App functionality** (Hyper-local weather telemetry, nocturnal hypoxia risk evaluation)

2. **Precise Location (`ACCESS_FINE_LOCATION`)**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** No
   - **Required or Optional?** **Optional**
   - **Purposes:** **App functionality** (Pinpointing pond coordinates for coastal microclimate weather forecasts and identifying the nearest aquaculture trade mandi)

---

#### B. Personal Information
1. **Name**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** No
   - **Required or Optional?** Optional (Defaults to "Farmer")
   - **Purposes:** **App functionality**, **Account management**

2. **Phone Number**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** No
   - **Required or Optional?** **Required** (Primary authentication key via passwordless OTP)
   - **Purposes:** **App functionality**, **Account management**, **Developer communications**

---

#### C. Photos and Videos
1. **Photos**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** No (Saved in private user scan history so the farmer can review pathology progression)
   - **Required or Optional?** **Optional** (Only needed when using PrawnDoc Vision AI or computer vision ABW sampling)
   - **Purposes:** **App functionality** (Diagnostic pathology classification across 12 shrimp diseases and visual ABW growth sampling)

---

#### D. Audio Files
1. **Voice or sound recordings**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** **Yes** (Audio stream is processed immediately by the Telugu Voice NLU engine to transcribe telemetry values and is **instantly deleted**. No voice recordings are stored on servers or local disk.)
   - **Required or Optional?** **Optional** (Farmers can enter water parameters via keyboard/sliders)
   - **Purposes:** **App functionality** (Voice-activated pond telemetry logging)

---

#### E. Financial Information
1. **Other financial info (Aquaculture Expenses & Harvest Revenue)**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** No (Stored in user's farm financial ledger)
   - **Required or Optional?** **Optional**
   - **Purposes:** **App functionality** (PrawnCredit farm accounting, FCR calculation, cashflow analytics)

---

#### F. App Info and Performance
1. **Crash logs & Diagnostics**
   - **Collected?** Yes
   - **Shared?** No
   - **Processed ephemerally?** Yes
   - **Required or Optional?** Optional
   - **Purposes:** **Analytics**, **App functionality** (Debugging offline sync queue failures)

---

## Part 2: App Access (Reviewer Credentials) Instructions

Navigate in Google Play Console to:  
**Policy and programs > App content > App access > Manage**.

* Select: **All or some functionality in my app is restricted**
* Click: **+ Add instructions**

### Reviewer Access Configuration Card:

| Field | Value to Enter in Play Console |
| :--- | :--- |
| **Instruction name** | `Google Play Reviewer Demo Credentials` |
| **Username / Phone number** | `9876543210` |
| **Password / OTP** | `123456` |
| **Any other access details** | *(Copy and paste the explanation below)* |

```text
Welcome Google Play Review Team!

PrawnGuard.ai / AquaVerse is an AI-powered aquaculture operations platform for shrimp farmers in India.
To ensure full, immediate access to all 10 core features without requiring an Indian physical SIM card or SMS gateway, we have configured a universal automated review bypass:

STEP-BY-STEP REVIEWER INSTRUCTIONS:
1. Launch PrawnGuard.ai to the Login screen (/login).
2. The phone number field is prefilled with our test reviewer number: 9876543210
3. Tap "Send OTP" (or "Get Verification Code").
4. Enter the universal reviewer OTP: 123456
5. Tap "Verify & Login" to enter the app dashboard.

DEMO DATA & FEATURE TESTING:
- On the Home Dashboard (/home), tap the "Load Demo Farm" button to immediately populate 4 active shrimp ponds, live water parameters, and telemetry charts.
- PrawnDoc Vision AI (/prawndoc): Tap "Diagnose Disease" and select a test shrimp photo or camera feed to verify the Gemini 1.5 Flash pathology classifier. If testing on an emulator without a camera sensor, automated fallback diagnosis and sample images are provided.
- Telugu Voice Logging (/telemetry): Tap the microphone icon or type Telugu/English telemetry ("Pond 1 pH 7.8 DO 4.5") to test the NLU parameter extractor.
- Feed AI Calculator (/feed): View the automated 4-meal feed ration and check-tray adjustment calculations.
- Live Mandi Prices (/market-prices): Real-time daily shrimp prices across Bhimavaram, Nellore, and other aquaculture trade hubs.
- Nocturnal Hypoxia Warning Siren (/weather): Tap "Test Siren" to verify high-priority emergency audio alarms.

No physical sensors or live ponds are required to inspect 100% of the platform capabilities.
Technical contact: support@prawnguard.ai | privacy@prawnguard.ai
```

---

## Part 3: Privacy Policy URL Configuration

Navigate in Google Play Console to:  
**Policy and programs > App content > Privacy policy**.

* **Privacy Policy URL:**  
  `https://prawnguard.ai/privacy`  
  *(Hosted directly from `docs/PRIVACY_POLICY.md` on our public landing domain or GitHub Pages repo)*
