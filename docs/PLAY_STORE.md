# Play Store + Google Sign-In (Android)

SpendPing is built so you can upload an **Android App Bundle** to Google Play. Google login uses the official Google Sign-In SDK (and Firebase Auth when you add a Firebase project).

## 1. Google Cloud / Firebase

1. Create a Firebase project (or a Google Cloud project).
2. Add an Android app with package name **`com.spendping.spendping`**.
3. Download `google-services.json` into `android/app/google-services.json` (do not use the `.example` file as-is).
4. Enable **Google** under Authentication → Sign-in method.
5. Create an OAuth **Web client** (type 3). Copy its client ID.
6. Add SHA-1 (and SHA-256) fingerprints:
   - Debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Upload keystore you create below
   - **Play App Signing** certificate from Play Console → App integrity (required after first upload)

Build with the web client ID so Android receives an ID token:

```bash
flutter build appbundle --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Until `google-services.json` exists, Gradle skips the Google Services plugin. Continue with Google still works on-device using the Google account picker; cloud restore needs Firebase.

## 2. Signing for Play

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and fill in the passwords and `storeFile` path. `key.properties` is gitignored.

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console.

Do **not** ship a debug-signed AAB. If `key.properties` is missing, release still signs with the debug key for local testing only.

## 3. Play Console checklist

- Target API 35, min SDK 24, application id `com.spendping.spendping`
- Privacy policy URL (location + account data)
- Data safety: location (app functionality, on-device), personal info if Google email is stored
- Photos / video for **background location** if you keep “Allow all the time”
- Prominent in-app disclosure before requesting background location (Home → Enable location intelligence)
- No ads → Advertising ID permission is removed in the manifest
- Content rating questionnaire
- Store listing: icon, feature graphic, screenshots, short description

## 4. Google Places (restaurant names)

To name a stay at a restaurant from Google’s place data (official Nearby Search, not scraping Maps):

1. Enable **Places API** on the same Google Cloud project.
2. Restrict the key to this Android package + SHA-1, and to Places / Geocoding.
3. Put the key in `android/app/src/main/res/values/strings.xml` as `google_maps_key`, **or** pass `--dart-define=GOOGLE_MAPS_API_KEY=...`

When you stay still for a few minutes, SpendPing takes a high-accuracy fix, asks Nearby Search, and remembers **Vaishali Restaurant** (etc.) as a place. It still **does not** create an expense until you confirm.

Without a key, the OS reverse-geocoder is used (street names, weaker for shops).

## 5. Home widget

Tap **Add spend** on the widget. Type the amount (keyboard), choose **Food** or **Fuel**, or **Other** (cursor moves to type a name), then **Save**. That row appears in today’s spends.
