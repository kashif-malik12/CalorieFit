# Play Store Release

## Goal

Prepare CalorieFit for its first Google Play release.

## Current Status

Ready:
- Android app builds successfully.
- Release signing is now wired to `android/key.properties` when present.
- Branding assets and launcher icons already exist.
- App has been tested on a physical Android device.

Blocked / still required:
- Final Android package ID is now `com.caloriefit.app`; use that exact ID in Play Console.
- Generate a real upload keystore.
- Create `android/key.properties` that points to the upload keystore.
- Create a public privacy policy URL.
- Replace placeholder contact details in `doc/PRIVACY_POLICY_DRAFT.md`.
- Keep an in-app privacy policy screen or link in the shipped app build.
- Prepare Play Console store listing assets and declarations.
- Build and upload a signed `.aab` using the real upload key.

## Code / Repo Tasks

### 1. Choose the final package name

Current value:
- `android/app/build.gradle.kts`:
  - `namespace = "com.caloriefit.app"`
  - `applicationId = "com.caloriefit.app"`
- `android/app/src/main/kotlin/com/caloriefit/app/MainActivity.kt`

Notes:
- Package names are unique and permanent in Google Play.
- Do not create the Play Console app until this value is final.

Chosen value:
- `com.caloriefit.app`

### 2. Generate the upload keystore

Keep it outside version control.

Template file:
- `android/key.properties.example`

Expected real file:
- `android/key.properties`

Minimal file contents:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

### 3. Configure signing

Already prepared:
- `android/app/build.gradle.kts` now reads `android/key.properties` for release signing.
- If the file is missing, release builds now fail fast instead of falling back to debug signing.

### 4. Build the Play artifact

Use Android App Bundle for Play:

```powershell
C:\flutter\bin\flutter.bat build appbundle --dart-define-from-file=env/dart_defines.local.json
```

Expected output:
- `build/app/outputs/bundle/release/app-release.aab`

Important:
- USDA search in the released app will only work if the AAB is built with the USDA key included.
- In VS Code, use the `Flutter Build AAB` task so `env/dart_defines.local.json` is applied automatically.
- If you build with plain `flutter build appbundle` and omit the Dart define file, the release app will show USDA search as not configured.

## Play Console Tasks

### App setup

- Create the app in Play Console.
- Set the final app name.
- Choose app category and contact email.
- Accept Play App Signing.

### Store listing

Prepare:
- App name
- Short description
- Full description
- App icon
- Phone screenshots
- Feature graphic

Character limits from Play Console Help:
- App name: 30
- Short description: 80
- Full description: 4000

### Privacy / declarations

Before submission:
- Add a privacy policy URL in Play Console.
- Show privacy policy text or link inside the app.
- Complete the Data safety form based on actual app behavior.
- Complete App access if reviewers need instructions to use the app.
- Confirm the app does not use any restricted permissions that require a Permissions Declaration.

## Current App-Specific Notes

- The app is local-first and does not currently require an account.
- The app stores food logs and settings locally on device.
- The app uses the internet only for optional USDA food search.
- The app currently requests only:
  - `android.permission.INTERNET`

## Recommended First Release Flow

1. Keep `com.caloriefit.app` as the permanent Play package name.
2. Generate keystore and create `android/key.properties`.
3. Replace privacy policy placeholders and publish it to a public HTTPS page.
4. Keep the in-app privacy policy screen or link enabled in the release build.
5. Build a signed `.aab`.
6. Create Play Console app entry.
7. Upload `.aab` to internal testing first.
8. Complete store listing, Data safety, and app content declarations.
9. Fix any pre-launch report issues.
10. Promote to production.

## Official References

- Google Play app setup and store listing:
  - https://support.google.com/googleplay/android-developer/answer/9859152
- Target API level requirement:
  - https://developer.android.com/google/play/requirements/target-sdk
- User Data / privacy policy / Data safety:
  - https://support.google.com/googleplay/android-developer/answer/10144311
- Permissions declaration process:
  - https://support.google.com/googleplay/android-developer/answer/9214102

## Decision Needed From You

The main unresolved technical choice is the final Android package name.

Until that is chosen, the release can be prepared, but not finalized for Play Store publication.
