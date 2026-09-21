# PrawnGuard.ai — iOS Build & Installation Instructions

---

## ⚡ FAST TRACK 1: Install Pre-Built Native iOS App (.ipa) in 2 Minutes
*(Works on Mac OR Windows PC — No Xcode / No CocoaPods needed!)*

A native iOS `.ipa` has already been compiled by the GitHub Actions Apple Silicon cloud runner:

1. **Download the pre-built `.ipa` from GitHub Actions**:
   - Open: **[GitHub Actions Run #35585949623](https://github.com/iblamesurya/sih_2026/actions/runs/35585949623)**
   - Scroll down to the bottom under **Artifacts**.
   - Click **`prawnguard-ios-unsigned-ipa`** to download it.
   - Unzip the downloaded file to get `PrawnGuard-iOS-unsigned.ipa`.

2. **Install using Sideloadly (100% Free)**:
   - Download & open **[Sideloadly](https://sideloadly.io/)** on your Mac or Windows PC.
   - Connect your iPhone to your computer via USB cable (unlock iPhone and tap "Trust This Computer" if prompted).
   - Drag and drop `PrawnGuard-iOS-unsigned.ipa` into Sideloadly.
   - Enter your Apple ID email.
   - Click **Start**.

3. **Trust Developer on iPhone (First Time Only)**:
   - On your iPhone: Go to **Settings** > **General** > **VPN & Device Management**.
   - Tap your Apple ID email under *Developer App* > Tap **Trust**.
   - **Done!** The native PrawnGuard.ai app icon is now on your iPhone home screen.

---

## ⚡ FAST TRACK 2: One-Liner for MacBook Terminal
*(If you are sitting at your MacBook with your iPhone connected)*

Open Terminal on your Mac and run this one command:
```bash
git clone https://github.com/iblamesurya/sih_2026.git && cd sih_2026 && flutter pub get && cd ios && pod install && cd .. && flutter run
```

---

## 🤖 COMPREHENSIVE INSTRUCTIONS FOR ANTIGRAVITY ON MAC

If you open this repository in **Antigravity on your MacBook**, tell Antigravity:
> *"Please read INSTRUCTIONS.md, verify the CocoaPods setup, and launch the app on my iPhone (or iOS Simulator)."*

Here is the exact technical execution guide:

### Phase 1: Environment & Toolchain Verification
```bash
# 1. Check Flutter & iOS toolchain health
flutter doctor -v

# 2. Ensure Xcode command line tools are selected:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Phase 2: Dependency Resolution & Pod Setup
```bash
# Fetch Flutter & Dart packages
flutter pub get

# Install native iOS CocoaPods dependencies
cd ios
pod install --repo-update
cd ..
```

### Phase 3: Automated Quality Gate
```bash
# Verify all 281 tests pass
flutter test
```

### Phase 4: Launching on iOS Device / Simulator

#### Option A: iOS Simulator
```bash
open -a Simulator
flutter devices
flutter run -d ios
```

#### Option B: Physical iPhone via USB
1. Open native workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select **Runner** target > **Signing & Capabilities**.
3. Check **"Automatically manage signing"** and select your personal **Apple ID Team**.
4. On iPhone: Ensure **Developer Mode** is ON (**Settings** > **Privacy & Security** > **Developer Mode**).
5. Launch to your device:
   ```bash
   flutter run -d <your-iphone-device-id>
   ```

---

## 🏗️ Phase 5: Building Distribution IPA from Source
```bash
# Build unsigned release archive
flutter build ipa --no-codesign \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL="https://xyzcompany.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_key"
```
The output will be generated in `build/ios/archive/` and `build/ios/ipa/`.

---

## 🔒 Pre-configured iOS Permissions (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription`: Camera access for PrawnDoc AI shrimp disease scanning.
- `NSPhotoLibraryUsageDescription`: Photo gallery access for uploading pond/shrimp photos.
- `NSLocationWhenInUseUsageDescription`: GPS access for localized weather advisories & hypoxia risk.
- `NSMicrophoneUsageDescription`: Audio access for Telugu voice telemetry notes.
