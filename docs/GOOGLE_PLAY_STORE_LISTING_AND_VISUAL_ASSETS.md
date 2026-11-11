# PrawnGuard.ai (AquaVerse) — Google Play Store Listing & Visual Assets Package
**Enterprise Aquaculture Intelligence & FinTech Platform | SIH 2026 Production Release**

---

## 1. Visual Asset Specifications & Production Design Prompts

Google Play Store visual assets must adhere strictly to Google Play Asset Guidelines (Updated 2026) and the **Deep Ocean Matte** design language (`#0A0A0B` background, `#171717` card surfaces, `#00E5FF` electric cyan, `#10B981` emerald green, and `#E55C5C` urgent coral red).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              PLAY STORE GRAPHIC SPECIFICATIONS                         │
├─────────────────────┬──────────────────┬─────────────┬─────────────┬───────────────────┤
│ Asset Type          │ Resolution       │ Aspect Ratio│ File Format │ Transparency      │
├─────────────────────┼──────────────────┼─────────────┼─────────────┼───────────────────┤
│ App Icon            │ 512 x 512 px     │ 1:1         │ 32-bit PNG  │ Alpha allowed     │
│ Feature Graphic     │ 1024 x 500 px    │ 1024:500    │ 24-bit JPG  │ NO Alpha (Opaque) │
│ Phone Screenshots   │ 1080 x 2400 px   │ 9:20        │ 24-bit PNG  │ NO Alpha (Opaque) │
└─────────────────────┴──────────────────┴─────────────┴─────────────┴───────────────────┘
```

---

### 1.1 App Icon (512 x 512 px, 32-bit PNG)

#### Technical Guidelines:
- **Final Canvas:** `512 x 512 px`, 32-bit PNG with alpha channel, maximum 1024 KB.
- **Safe Zone:** Center circle/squircle of `424 x 424 px` (44px margins on all 4 sides). Google Play automatically applies an adaptive squircle mask and drop shadow. Never bake corner rounding or shadows into the raw asset.

#### Visual Composition:
- **Base Background:** Deep Ocean Matte dark circular gradient (`#0A0A0B` at center to `#040405` at edges).
- **Hero Iconography:** A stylized, aerodynamic shrimp (*Litopenaeus vannamei*) silhouette drawn in clean vector lines, transitioning into a digital biometric telemetry wave (cyan `#00E5FF` to emerald `#10B981`).
- **Foreground Accents:** A high-contrast central shield contour with a subtle glowing pulse node at the top right, signifying 24/7 AI protection and emergency vigilance.

#### Generative AI Prompt (Midjourney v6 / DALL-E 3 / Google Imagen 3):
```text
App icon design for an enterprise aquaculture AI mobile application named "PrawnGuard". Centered minimalist vector icon on a pure dark matte background (#0A0A0B). The icon features a glowing geometric shrimp silhouette seamlessly fused with a digital biometrics pulse line and a protective security shield contour. High-contrast neon electric cyan (#00E5FF) and vibrant emerald green (#10B981) glowing gradients. Premium, sleek modern fintech aesthetic, flat 2D vector style with subtle inner depth, sharp edges, Apple-inspired human interface guidelines, no realistic shrimp photography, no text, no letters, no words, no 3D photorealistic shadows, perfectly centered with generous negative padding, 512x512 resolution --v 6.0 --q 2 --style raw
```

---

### 1.2 Feature Graphic (1024 x 500 px, JPG/PNG Opaque)

#### Technical Guidelines:
- **Dimensions:** `1024 x 500 px`, 24-bit PNG or high-quality JPG (zero alpha/transparency).
- **Safe Zone:** Keep all critical text, branding, and device mockups within the central `820 x 380 px` container (leaving 102px margins left/right and 60px margins top/bottom) to avoid cut-off across Android tablets, foldables, and TV form factors.

#### Visual Composition:
- **Left Region (Focal Messaging):**
  - **Brand Header:** `PrawnGuard.ai` in bold `Space Grotesk` font with Electric Cyan accent (`#00E5FF`).
  - **Hero Tagline:** *"AI Aquaculture Intelligence & Emergency Protection"*
  - **Key Badges:** 3 sleek floating badge pills:
    - `[📷 5-Sec PrawnDoc AI]`
    - `[🎙️ Spoken Telugu Diary]`
    - `[🚨 24/7 Hypoxia Alarm]`
- **Right Region (3D Device Showcase):**
  - Angled isometric 3D render of a flagship Android device (Pixel 9 Pro) floating with a gentle cyan underglow.
  - Device screen displays the live Deep Ocean Matte Command Center: Dissolved Oxygen dial at `6.2 mg/L` (Optimal Green), biometric sparklines, and active WSSV pathology scanner.
- **Background Atmosphere:** Cinematic twilight prawn pond landscape across coastal Andhra Pradesh with active paddlewheel aerators churning water into luminous white-cyan foam, illuminated by midnight moonlight.

#### Generative AI Prompt (Midjourney v6 / DALL-E 3):
```text
Cinematic 1024x500 banner graphic for a Google Play Store feature graphic. Dark ocean matte aesthetic (#0A0A0B). On the left half, bold modern futuristic typography reading "PrawnGuard.ai" in glowing electric cyan (#00E5FF) and crisp white, with floating matte dark UI badges for "Camera Disease AI" and "Telugu Voice Diary". On the right half, a sleek modern bezel-less smartphone floating at an isometric angle displaying an aquaculture telemetry dashboard with glowing circular gauges for Oxygen and pH. In the deep background, a coastal shrimp aquaculture pond at dusk with paddlewheel aerators splashing water under a starry sky with subtle cyan atmospheric fog. High dynamic range, professional commercial app marketing art, 8k render, octane render style --ar 1024:500 --v 6.0 --style raw
```

---

### 1.3 6 High-Impact Store Screenshots (1080 x 2400 px, 9:20 Aspect Ratio)

Every screenshot utilizes a standardized 3-zone layout:
1. **Top Zone (20% height = 480px):** High-contrast headline banner with dual-language value proposition (Bold English Title + Crisp Telugu Subtitle).
2. **Center Zone (70% height = 1680px):** Framed flagship device mockup displaying the actual production screen from `lib/` in Deep Ocean Matte theme.
3. **Bottom Zone (10% height = 240px):** Social proof or feature proof badge (e.g., *"100% Offline-First"*, *"Powered by Gemini 1.5 Flash"*).

---

#### 📱 Screenshot 1: PrawnDoc AI (5-Second Camera Disease Scanner)
- **Top Banner:**  
  **Headline (EN):** `5-Second AI Disease Scanner`  
  **Subtitle (TE):** `5 సెకన్లలో రొయ్యల వ్యాధి నిర్ధారణ`
- **Device Screen UI:** Camera viewfinder overlay framing an adult *Litopenaeus vannamei* shrimp with holographic cyan bounding box. Pathology triage result card pinned to bottom:
  - Disease: **White Spot Syndrome Virus (WSSV / తెల్లమచ్చ వ్యాధి)**
  - Confidence: **96.4%** | Severity: **Critical (అత్యవసరం)**
  - Immediate Action: *"Bird netting active, isolate pond water intake, add Sodium Percarbonate 2.5 kg/acre."*
- **Footer Badge:** `⚡ 12+ Shrimp Pathologies Detected Instantly`

---

#### 📱 Screenshot 2: Telugu Voice NLU (Hands-Free Speech Logging)
- **Top Banner:**  
  **Headline (EN):** `Hands-Free Telugu Voice Logging`  
  **Subtitle (TE):** `మాట్లాడితే చాలు — చెరువు డైరీ ఆటోమేటిక్!`
- **Device Screen UI:** Microphone active state with pulsing cyan/emerald audio waveform and floating speech card:
  - Spoken Transcript: *"చెరువు ఒకటిలో పీహెచ్ 7.9, ఆక్సిజన్ 4.8, అమ్మోనియా సున్నా, మేత 30 కేజీలు వేసాను"*
  - Extracted Telemetry Card: `Pond 1` | `pH: 7.9` | `DO: 4.8 ppm` | `NH3: 0.0 ppm` | `Feed: 30 kg`
- **Footer Badge:** `🎙️ Works in Rayalaseema & Coastal Spoken Telugu`

---

#### 📱 Screenshot 3: Bio-Energetic Feed AI (4-Meal Precision Feeding)
- **Top Banner:**  
  **Headline (EN):** `Bio-Energetic 4-Meal Feed AI`  
  **Subtitle (TE):** `మేత ఖర్చులో ₹1.5 లక్షలు ఆదా చేసుకోండి`
- **Device Screen UI:** Feed AI daily plan screen:
  - Daily Total: **124.5 kg** (Target FCR: **1.22**)
  - Meal Schedule:
    - `06:00 AM (20%): 24.9 kg` [✓ Completed]
    - `11:00 AM (30%): 37.4 kg` [✓ Completed]
    - `04:00 PM (30%): 37.4 kg` [Upcoming]
    - `09:00 PM (20%): 24.8 kg` [Upcoming]
  - Interactive Check-Tray Feedback Slider: *"Tray 10% Leftover -> Next meal adjusted by -5%"*
- **Footer Badge:** `📉 Eliminates Ammonia & Toxic Sludge Buildup`

---

#### 📱 Screenshot 4: 24/7 Hypoxia Emergency Alarm & Weather Intelligence
- **Top Banner:**  
  **Headline (EN):** `24/7 Hypoxia Emergency Siren`  
  **Subtitle (TE):** `అర్ధరాత్రి ఆక్సిజన్ పడిపోతే ఫోన్ సైరన్ మోగుతుంది`
- **Device Screen UI:** Flashing urgent red HUD (`#E55C5C`):
  - Alarm Banner: **CRITICAL HYPOXIA RISK PREDICTED AT 03:15 AM**
  - Weather Correlation: Heavy cloud cover (88%), barometric drop (1004 hPa), DO trending down to `2.6 mg/L`.
  - Emergency Action Checklist:
    1. Turn ON all paddlewheel aerators immediately.
    2. Broadcast 3 kg/acre oxygen tablets (Sodium Percarbonate).
- **Footer Badge:** `🚨 Wakes You Up Before Nocturnal Die-Offs`

---

#### 📱 Screenshot 5: Live Mandi Market Prices (Anti-Middleman Rates)
- **Top Banner:**  
  **Headline (EN):** `Live Mandi Rates Across AP`  
  **Subtitle (TE):** `దళారుల మోసాలకు చెక్ — సరైన ధరకు రొయ్యలు అమ్మండి`
- **Device Screen UI:** Mandi Market Rates board:
  - Hub Selector: `Bhimavaram (West Godavari)` [Active] | `Nellore` | `Kakinada`
  - Daily Rate Cards:
    - **30 Count:** `₹420 / kg` (+₹15) [High Demand]
    - **40 Count:** `₹360 / kg` (+₹10) [Very High Demand]
    - **50 Count:** `₹310 / kg` (-₹5) [Stable]
    - **100 Count:** `₹195 / kg` [Moderate]
  - 30-Day Historical Price Trend Curve with exporter buying volume indicator.
- **Footer Badge:** `💰 Prevents ₹1.25 Lakhs Loss Per Harvest`

---

#### 📱 Screenshot 6: Farm Finance & PrawnCredit Ledger
- **Top Banner:**  
  **Headline (EN):** `Farm Finance & PrawnCredit`  
  **Subtitle (TE):** `చెరువు లాభనష్టాలు & బ్యాంకు క్రెడిట్ స్కోరు`
- **Device Screen UI:** Financial Overview & Creditworthiness Dashboard:
  - Net Profit Card: **₹4,85,200** (Crop Cycle #4, 98 DOC)
  - Expense Ledger Breakdown: Feed (64%), Seed PL (14%), Electricity/Diesel (12%), Chemicals (10%).
  - **PrawnCredit Gauge:** `785 / 900` (Excellent Creditworthiness)
  - Bank Ready PDF Export Button with QR-verified crop history for institutional agricultural credit.
- **Footer Badge:** `🏛️ Backed by Audited FCR & Survival Records`

---

## 2. Store Listing Localization Package (English & Telugu)

Google Play Store enforces strict character limitations:
- **App Title:** Maximum 30 characters
- **Short Description:** Maximum 80 characters
- **Full Description:** Maximum 4000 characters (supports `<b>`, `<i>`, `•`, `<br>`)

---

### 2.1 English Listing (`en-IN` / `en-US`)

#### App Title (29 / 30 chars):
```text
PrawnGuard: Shrimp Farming AI
```

#### Short Description (80 / 80 chars):
```text
AI disease scanner, Telugu voice logging, 4-meal feed calc & live mandi prices.
```

#### Full Description (Formatted Google Play HTML):
```html
<b>PrawnGuard.ai (AquaVerse)</b> is India’s premier AI-powered aquaculture intelligence and farm management ecosystem built specifically for commercial shrimp farmers (<i>Litopenaeus vannamei</i> & <i>Penaeus monodon</i>). 

Protect your valuable shrimp crop from sudden disease crashes, cut feed wastage by ₹1.5 Lakhs per pond, wake up to midnight oxygen alarms, and trade at true market prices—<b>100% offline-first with zero typing required!</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>WHY SHRIMP FARMERS CHOOSE PRAWNGUARD</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• <b>5-Second Camera Disease Scanner (PrawnDoc AI):</b> Snap a single photo of a sick prawn. Google Gemini 1.5 Flash vision diagnoses 12+ lethal diseases (WSSV White Spot, White Gut, EHP Stunting, RMS, Black Gill, Vibriosis) with immediate dosage protocols in simple Telugu.
• <b>Hands-Free Telugu Voice Logging:</b> Wet or muddy hands? Simply speak in your natural voice: <i>"Pond 1, pH 7.8, Oxygen 5.2, fed 35 kg."</i> Our on-device Telugu Natural Language engine logs your pond diary automatically.
• <b>Bio-Energetic 4-Meal Feed Calculator:</b> Stop guessing feed quantities. Calculates exact daily biomass requirements and splits rations across standard diurnal schedules (6 AM, 11 AM, 4 PM, 9 PM) with check-tray feedback adjustments (-20% to +10%).
• <b>24/7 Midnight Hypoxia Emergency Siren:</b> Predicts dangerous Dissolved Oxygen (DO) crashes hours before they happen using micro-weather intelligence, sounding a loud siren on your phone to wake you up before mortality occurs.
• <b>Daily Live Mandi Market Rates:</b> Real-time count prices (30c, 40c, 50c, 100c) across major Andhra Pradesh trading hubs (Bhimavaram, Nellore, Kakinada, Machilipatnam, Ongole) to protect you from middlemen syndicates.
• <b>PrawnCredit & P&L Ledger:</b> Track feed, seed PL, electricity, and chemical expenses. Compute exact FCR and generate bank-ready creditworthiness reports for low-interest aquaculture crop loans.
• <b>100% Offline-First Architecture:</b> Zero mobile signal at your remote pond? No problem! PrawnGuard stores all logs securely on your device and synchronizes seamlessly in the background when connectivity returns.

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>DISEASES IDENTIFIED BY PRAWNDOC AI</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• White Spot Syndrome Virus (WSSV)
• White Feces Syndrome / White Gut Disease (WFS / WGD)
• Enterocytozoon hepatopenaei (EHP Stunting)
• Running Mortality Syndrome (RMS)
• Black Gill Disease
• Loose Shell Syndrome (LSS)
• Vibriosis & Bacterial Septicemia
• Muscle Necrosis & Cramped Tail

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>REGIONAL MANDI COVERAGE</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Daily procurement rates updated at 08:30 AM for:
• Bhimavaram (West Godavari)
• Nellore & Gudur (Nellore District)
• Kakinada & Amalapuram (East Godavari)
• Machilipatnam & Kaikaluru (Krishna District)
• Bapatla & Ongole (Prakasam District)
• Surat (Gujarat Aquaculture Belt)

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>DATA PRIVACY & BIOSECURITY COMMITMENT</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your farm data, GPS coordinates, and harvest logs belong strictly to you. PrawnGuard never shares your yields or financial records with seed hatcheries, feed suppliers, or brokers. All telemetry is encrypted end-to-end via TLS 1.3.

Download <b>PrawnGuard.ai</b> today and safeguard your harvest with next-generation aquaculture intelligence!
```

---

### 2.2 Telugu Listing (`te-IN`)

#### App Title (26 / 30 chars):
```text
PrawnGuard: రొయ్యల సాగు AI
```

#### Short Description (75 / 80 chars):
```text
కెమెరా వ్యాధి స్కానర్, తెలుగు వాయిస్ డైరీ, మేత AI & లైవ్ మార్కెట్ రేట్లు.
```

#### Full Description (Formatted Google Play HTML):
```html
<b>PrawnGuard.ai (ఆక్వావర్స్)</b> అనేది ఆంధ్రప్రదేశ్ మరియు తెలంగాణ రొయ్యల రైతుల (వెనామి & టైగర్ రొయ్యల సాగు) కోసం ప్రత్యేకంగా రూపొందించబడిన మొట్టమొదటి కృత్రిమ మేధస్సు (AI) ఆధారిత మొబైల్ అప్లికేషన్.

లక్షల రూపాయల పెట్టుబడితో కూడిన రొయ్యల పంటను ఆకస్మిక వ్యాధులు మరియు అర్ధరాత్రి ఆక్సిజన్ పడిపోవడం నుండి కాపాడుకోండి. మేత వృథాను అరికట్టండి మరియు దళారుల మోసాలకు తావులేకుండా సరైన మార్కెట్ ధరకు పంటను అమ్ముకోండి. <b>100% ఆఫ్‌లైన్‌లో పనిచేస్తుంది — ఇంగ్లీష్ టైపింగ్ అవసరమే లేదు!</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>రైతులకు PRAWNGUARD అందించే ముఖ్య ఫీచర్లు:</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• <b>5 సెకన్లలో కెమెరా వ్యాధి స్కానర్ (PrawnDoc AI):</b> జబ్బుపడిన రొయ్య ఫోటో తీస్తే చాలు! అధునాతన AI విజన్ ఇంజిన్ క్షణాల్లో వ్యాధిని (తెల్లమచ్చ, తెల్ల రెట్ట, EHP, నల్ల మొప్పలు) గుర్తించి, వాడాల్సిన మందులు మరియు మోతాదులను స్పష్టమైన తెలుగులో తెలియజేస్తుంది.
• <b>తెలుగు వాయిస్ డైరీ (టైపింగ్ లేకుండా):</b> చెరువు గట్లపై తడి చేతులతో టైప్ చేయడం కష్టమా? మైక్ బటన్ నొక్కి తెలుగులో మాట్లాడండి: <i>"చెరువు 1 లో పీహెచ్ 7.8, ఆక్సిజన్ 5.2, 35 కేజీల మేత వేసాను."</i> యాప్ ఆటోమేటిక్‌గా మీ చెరువు రికార్డును నమోదు చేస్తుంది.
• <b>బయో-ఎనర్జిటిక్ 4-పూటల మేత కాలిక్యులేటర్:</b> అంచనాతో మేత వేసి డబ్బులు వృథా చేయకండి. రొయ్యల సైజు, బరువు (ABW), ఉష్ణోగ్రత మరియు చెక్-ట్రే ఆధారంగా రోజువారీ 4 పూటలకు (ఉదయం 6, 11, సాయంత్రం 4, రాత్రి 9 గంటలకు) ఖచ్చితమైన మేత పరిమాణాన్ని లెక్కిస్తుంది.
• <b>24/7 అర్ధరాత్రి ఆక్సిజన్ ఎమర్జెన్సీ సైరన్ (Hypoxia Alert):</b> అర్ధరాత్రి 2 నుండి తెల్లవారుజామున 5 గంటల మధ్య ఆక్సిజన్ పడిపోయే ప్రమాదం ఉంటే, వాతావరణాన్ని విశ్లేషించి మీ ఫోన్‌లో పెద్ద సైరన్ మోగించి మిమ్మల్ని మేల్కొల్పుతుంది.
• <b>తాజా మార్కెట్ రేట్లు (Mandi Prices):</b> భీమవరం, నెల్లూరు, కాకినాడ, మచిలీపట్నం మార్కెట్లలో 30, 40, 50, 100 కౌంట్ రొయ్యల అధికారిక కొనుగోలు ధరలను ప్రతిరోజూ తెలుసుకోండి. దళారుల తక్కువ రేట్ల మోసాలకు చెక్ పెట్టండి.
• <b>చెరువు ఖర్చులు & PrawnCredit స్కోరు:</b> మేత, సీడ్, కరెంట్ బిల్లులు మరియు లేబర్ ఖర్చులను లెక్కించండి. FCR సరిగ్గా ఉంచుకుని బ్యాంక్ లోన్ల కోసం PrawnCredit రిపోర్ట్‌ను డౌన్‌లోడ్ చేసుకోండి.
• <b>100% ఆఫ్‌లైన్ వర్కింగ్ (నెట్‌వర్క్ లేకపోయినా):</b> మీ చెరువు వద్ద సిగ్నల్ లేదా ఇంటర్నెట్ లేకపోయినా యాప్ సాఫీగా పనిచేస్తుంది. నెట్‌వర్క్ వచ్చినప్పుడు డేటా ఆటోమేటిక్‌గా సేవ్ అవుతుంది.

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>గుర్తించే రొయ్యల వ్యాధులు:</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• తెల్లమచ్చ వ్యాధి (WSSV)
• తెల్ల రెట్ట వ్యాధి / వైట్ గట్ (WFS / WGD)
• రొయ్య ఎదుగుదల ఆగిపోవడం (EHP Stunting)
• రన్నింగ్ మోర్టాలిటీ సిండ్రోమ్ (RMS)
• నల్ల మొప్పల వ్యాధి (Black Gill)
• గుల్ల మెత్తబడటం (Loose Shell Syndrome)
• తోక కుళ్ళు & కండరాల తెలుపు (Vibriosis)

━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>కవర్ చేయబడిన ప్రధాన మార్కెట్లు:</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━
ప్రతిరోజూ ఉదయం 8:30 గంటలకు లైవ్ ధరలు:
• పశ్చిమ గోదావరి (భీమవరం, నరసాపురం, పాలకొల్లు)
• నెల్లూరు (నెల్లూరు సిటీ, గూడూరు, కావలి)
• తూర్పు గోదావరి (కాకినాడ, అమలాపురం)
• కృష్ణా జిల్లా (మచిలీపట్నం, కైకలూరు)
• బాపట్ల & ప్రకాశం (ఒంగోలు, చీరాల)

ఈరోజే <b>PrawnGuard.ai</b> యాప్‌ను డౌన్‌లోడ్ చేసుకోండి — మీ రొయ్యల సాగులో లాభాలను రెట్టింపు చేసుకోండి!
```

---

## 3. Google Play Console Metadata & Questionnaires

### 3.1 Store Categorization & Tags
- **Application Type:** `App`
- **Primary Category:** `Business` (Alternative: `Productivity`)
- **Tags (Max 5):**
  1. `Agriculture`
  2. `Productivity`
  3. `Tools`
  4. `Business`
  5. `Artificial Intelligence`

### 3.2 Target Audience & Content Rating (IARC)
- **Target Age:** `18 and over` (Commercial farmers & aquaculture operators).
- **Does your app collect personal information from children under 13?** `No`.
- **IARC Content Rating Questionnaire Declarations:**
  - Violence: `No`
  - Sexuality: `No`
  - Language: `No`
  - Controlled Substances: `No`
  - User-generated content / Forums: `Yes` (Monitored community hub).
  - Shares User Location: `Yes` (Only for regional weather warnings and mandi rates; strictly not sold or shared with 3rd parties).
  - In-App Purchases: `Yes` (Optional Pro tier subscription via Google Play Billing).
- **Anticipated Rating:** `PEGI 3` / `ESRB Everyone` / `Google Play 3+` (Universal).

### 3.3 Contact Details for Store Listing
- **Developer Name:** `PrawnGuard Aquaculture Technologies`
- **Email:** `support@prawnguard.app`
- **Website:** `https://prawnguard.app`
- **Privacy Policy URL:** `https://prawnguard.app/privacy-policy`
