# Firebase (optional)

SpendPing runs fully offline without Firebase. Configure Firebase when you want Apple/Google sign-in and multi-device restore.

1. Create a Firebase project.
2. Add iOS app id `com.spendping.spendping` and Android app id `com.spendping.spendping`.
3. Download `GoogleService-Info.plist` into `ios/Runner/`.
4. Download `google-services.json` into `android/app/`.
5. Enable Authentication: Apple, Google, Email/password.
6. Create a Firestore database in production mode and deploy `firebase/firestore.rules`.
7. Add the Google Services Gradle plugin if you use Crashlytics later.
8. Run `flutterfire configure` or add `lib/firebase_options.dart`.

Until those files exist, `FirebaseBootstrap.tryInit()` fails closed and the app uses local accounts plus on-device SQLite.

Do not commit admin SDK keys or service-account JSON.
