# PrawnGuard.ai — iOS Build & Deployment Instructions (For Antigravity on Mac)

> **Role for Antigravity Agent:** You are running on macOS. Your objective is to prepare, verify, and run/build the PrawnGuard.ai Flutter application for iOS on either the iOS Simulator or a physical iPhone connected to this Mac.

---

## 📱 Project Summary

- **App Name:** PrawnGuard.ai (Enterprise Aquaculture Intelligence)
- **Framework:** Flutter 3.47+ (Dart 3.13+)
- **State Management:** Riverpod 2.6 (`flutter_riverpod`)
- **Navigation:** GoRouter 17 (`go_router`)
- **Backend:** Supabase BaaS + Gemini Vision AI (Edge Functions)
- **Target OS:** iOS 14.0+ (Universal iPhone / iPad)

---

## 🛠️ Phase 1: Environment & Toolchain Verification

Run these commands to verify the local Mac environment has Xcode and CocoaPods properly configured:

```bash
# 1. Check Flutter & iOS toolchain health
flutter doctor -v

# 2. If CocoaPods is missing, install it:
# sudo gem install cocoapods  (or: brew install cocoapods)

# 3. Ensure Xcode command line tools are selected:
# sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
# sudo xcodebuild -runFirstLaunch
```

---

## 📦 Phase 2: Dependency Resolution & Pod Setup

Execute from the project root (`sih_2026`):

```bash
# 1. Fetch Dart & Flutter dependencies
flutter pub get

# 2. Install native iOS CocoaPods dependencies
cd ios
pod install --repo-update
cd ..
```

---

## 🧪 Phase 3: Automated Quality Gate

Ensure 100% of the unit and end-to-end test suite passes:

```bash
flutter test
```
*(All 281 tests across Tiers 1–6 should pass cleanly).*

---

## 📲 Phase 4: Running the App

### Option A: Running on iOS Simulator (Fastest for UI/UX testing)

```bash
# 1. Launch iOS Simulator
open -a Simulator

# 2. List detected devices
flutter devices

# 3. Run the app
flutter run -d ios
```

---

### Option B: Deploying to a Physical iPhone

Apple requires every app installed on a physical iPhone to be signed with an Apple ID.

#### Step 1: Configure Apple Developer Signing in Xcode
1. Open the native workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the Xcode left navigator, click on **Runner** (top item).
3. Select the **Runner** target -> Click **Signing & Capabilities**.
4. Check **"Automatically manage signing"**.
5. Under **Team**, select your Apple ID / Personal Team (if not listed, click *Add an Account...* and sign in with your free Apple ID).
6. Xcode will automatically generate a free Personal Development Provisioning Profile.

#### Step 2: Enable Developer Mode on iPhone (iOS 16+)
- On the iPhone, go to **Settings** > **Privacy & Security** > scroll to **Developer Mode** > Toggle **ON** > Restart device.

#### Step 3: Run via Flutter
Connect your iPhone via USB (or Wi-Fi), unlock the screen, and run:
```bash
# 1. Verify your physical iPhone is detected
flutter devices

# 2. Run directly to your iPhone
flutter run -d <your-iphone-device-id>
```

#### Step 4: Trust Developer Certificate (First time only)
- If iOS shows *"Untrusted Developer"* when launching:
  Go to **Settings** > **General** > **VPN & Device Management** > Tap your Apple ID > Tap **Trust**.

---

## 🏗️ Phase 5: Building Release IPA

To produce a production or distribution `.ipa` archive:

```bash
# Build unsigned release archive
flutter build ipa --no-codesign \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL="https://xyzcompany.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_key"
```

To build a fully signed `.ipa` using Xcode:
```bash
flutter build ipa --export-method development
```
The output `.ipa` and `.xcarchive` will be generated in `build/ios/archive/` and `build/ios/ipa/`.

---

## 🔒 Security & Permissions Checklist (Already Configured)

The `ios/Runner/Info.plist` is pre-configured with required Apple privacy descriptions:
- `NSCameraUsageDescription` -> Shrimp disease scanning & pond water inspection.
- `NSPhotoLibraryUsageDescription` -> Photo gallery uploads.
- `NSLocationWhenInUseUsageDescription` -> Farm geolocation & localized weather alerts.
- `NSMicrophoneUsageDescription` -> Telugu voice input.
