# Privacy Policy for PrawnGuard.ai (AquaVerse)

**Effective Date:** November 11, 2026  
**Last Updated:** November 11, 2026  
**Applicable Application:** PrawnGuard.ai (AquaVerse Aquaculture Intelligence Platform)  
**Package Name:** `com.aquaverse.prawnguard` / `com.example.sih_2026`  

---

## 1. Introduction

PrawnGuard.ai ("AquaVerse", "we", "our", or "us") is dedicated to empowering shrimp and aquaculture farmers with cutting-edge artificial intelligence, real-time water quality monitoring, automated disease diagnosis, and precision feed optimization. We hold farmer data sovereignty, digital privacy, and transparent data stewardship as foundational values.

This Privacy Policy explains how our mobile application and cloud infrastructure collect, process, store, and safeguard your personal information, aquaculture telemetry, and device sensor data in compliance with Google Play Store Developer Policies and applicable data protection regulations.

By installing, registering for, or using PrawnGuard.ai, you consent to the practices described in this Privacy Policy.

---

## 2. Information We Collect and Purpose of Collection

We collect only the minimum data required to deliver core precision aquaculture capabilities:

### A. Account & Authentication Information
* **Data Collected:** Indian mobile phone number (10 digits), full name or farm alias, preferred regional language (Telugu or English), district, and state (e.g., West Godavari, Andhra Pradesh).
* **Purpose:** User authentication via secure one-time password (OTP), personalized advisory broadcasts, and multi-tenant access control.
* **Storage:** Stored in your private PostgreSQL profile on our secure cloud server governed by Row Level Security (RLS).

### B. Aquaculture Telemetry & Farm Records
* **Data Collected:** 
  * Pond configurations (water area in hectares, shrimp species *L. vannamei* / *P. monodon*, stocking density, Days of Culture - DOC).
  * Water quality parameters (pH, Dissolved Oxygen, Salinity, Water Temperature, Total Ammonia Nitrogen - TAN, Alkalinity, Turbidity).
  * Feeding logs (tray consumption rates, meal schedules, daily feed weight in kg).
  * Sampling data (Average Body Weight - ABW, Average Daily Growth - ADG, survival rates).
  * Farm financial records (feed/probiotic expenses, partial/final harvest yields, count per kg, mandi sale revenue).
* **Purpose:** Computing nocturnal hypoxia hazard predictions, generating precision 4-meal feed tables, evaluating pond carrying capacity, and generating farm cashflow ledgers.
* **Storage:** Stored in tenant-isolated database tables accessible only to the authenticated farmer and authorized technicians.

### C. Device Hardware & Sensor Data

| Sensor / Permission | Permission Name | Exact Purpose & Processing Behavior |
| :--- | :--- | :--- |
| **Camera** | `android.permission.CAMERA` | Used **exclusively** when the user initiates a disease scan in PrawnDoc Vision AI or computer vision ABW sampling. Images are transmitted securely over TLS to our AI diagnostic engine to identify shrimp pathologies (e.g., WSSV, EHP, RMS, Black Gill). We **never** access the camera in the background or capture ambient footage. |
| **Photos & Media** | `READ_MEDIA_IMAGES` / Gallery | Allows the user to select an existing shrimp photograph or pond check-tray image for diagnostic pathology analysis. No other private photos or files are accessed. |
| **Microphone & Audio** | `android.permission.RECORD_AUDIO` | Used **exclusively** when the farmer taps and holds the Telugu voice logging microphone button in the Telemetry Logging screen. The audio waveform is processed locally or ephemerally streamed to our Speech-to-Text Natural Language Understanding (NLU) model to extract water values (e.g., *"చెరువు 2 లో pH 7.8, DO 4.5"*). Audio files are **immediately discarded** after transcription; we do not retain voice recordings. |
| **Precise & Approximate Location** | `android.permission.ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Used to pinpoint pond GPS coordinates to retrieve hyper-local coastal weather forecasts (cloud cover, barometric pressure, wind speed, precipitation) for the **Nocturnal Hypoxia Warning Siren** and to locate the nearest aquaculture mandi trade hub (Bhimavaram, Nellore, Machilipatnam, Kakinada, Ongole). Coordinates are tied to farm profiles and **never** shared with third-party advertisers. |
| **Local Storage / Cache** | SQLite / `SharedPreferences` | Powers our **offline-first outbox synchronization**. Telemetry entered pondside without network connectivity is cached encrypted on device and drained in strict FIFO order once connectivity resumes. |

---

## 3. Data Sharing & Third-Party Disclosures

**We do NOT sell, rent, monetize, or trade farmer personal data, pond telemetry, or financial records to third-party advertisers, data brokers, or marketing networks.**

Data is shared only with trusted technical service providers strictly necessary to execute platform functions:
1. **Supabase Inc. (Database & Auth Infrastructure):** Cloud hosting, PostgreSQL database, Row Level Security enforcement, and serverless edge functions hosted in SOC2 Type II and ISO 27001 certified data centers.
2. **Google Cloud Platform (Gemini 1.5 Flash & Discovery Engine):** Multimodal AI inference for shrimp pathology diagnosis and ICAR-CIBA veterinary protocol grounding. Transmitted diagnostic images are processed via enterprise API with zero retention for model training.
3. **OpenWeatherMap API:** Coordinates transmitted anonymously to query meteorological data for hypoxia predictive models.
4. **Legal Compliance:** We may disclose data if required by law, subpoena, or government regulation, or to protect the safety of aquaculture biosecurity zones.

---

## 4. Data Security & Encryption in Transit

We employ enterprise-grade cybersecurity controls to protect your farm data:
* **Encryption in Transit:** All network traffic between the mobile application and cloud backend endpoints is strictly encrypted using **TLS 1.3 / HTTPS**. Unencrypted HTTP connections are rejected.
* **Row Level Security (RLS):** Database policies enforce strict tenant boundaries at the PostgreSQL kernel level. No farmer or technician can access or modify another user's pond records, financial ledgers, or telemetry logs.
* **Idempotent Mutation Security:** Offline mutations are signed with unique UUID idempotency keys to eliminate replay tampering and duplicate financial transactions.
* **Zero Service-Role Leakage:** Sensitive administrative and service keys are strictly confined to isolated serverless edge runtimes and are never bundled into the client APK or AAB.

---

## 5. Data Retention & Account Deletion (Play Store Compliance)

We respect your right to control, export, or permanently erase your data:

### A. Retention Period
* We retain account and farm telemetry records for as long as your account remains active to provide historical crop cycle analytics and multi-year ADG growth curves.

### B. User Account & Data Deletion
In full compliance with Google Play Store Account Deletion requirements:
* **In-App Deletion:** Farmers can request immediate, permanent deletion of their account and all associated farm records directly within the app by navigating to:  
  **More > Profile Settings > Delete Account & Farm Data**.
* **Web Deletion Request:** Users can also submit an account deletion request via email to `privacy@prawnguard.ai` or through our web portal at `https://prawnguard.ai/account-deletion`.
* **Execution:** Upon receipt of a verified deletion request, all personal identifiers, farm locations, pond profiles, water logs, feed records, disease scans, and financial entries are permanently and irreversibly purged from our active databases within **30 days**. Backups are purged within standard backup rotation cycles.

---

## 6. Children's Privacy

PrawnGuard.ai is designed specifically for commercial aquaculture producers, farm managers, technicians, and agricultural researchers (target audience: **Ages 18 and older**). The application does not intentionally collect or solicit personal information from individuals under the age of 18. If we discover that personal data from a child has been collected, we will take immediate steps to delete it.

---

## 7. Changes to this Privacy Policy

We may update this Privacy Policy periodically to reflect enhancements in our AI models, regional regulations, or cloud infrastructure. Significant updates will be communicated through an in-app notice, banner advisory, or push notification prior to implementation. Continued use of PrawnGuard.ai following such notification constitutes acceptance of the revised policy.

---

## 8. Contact & Data Protection Officer

For privacy inquiries, data subject access requests, or regulatory questions, contact our Data Protection Officer:

* **Entity:** PrawnGuard.ai / AquaVerse Aquaculture Intelligence Platform
* **Email:** `privacy@prawnguard.ai`
* **Technical Support:** `support@prawnguard.ai`
* **Location:** Andhra Pradesh & Telangana, India
* **Website:** `https://prawnguard.ai`
