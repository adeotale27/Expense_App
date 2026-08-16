# Firebase (optional cloud)

SpendPing runs fully offline without Firebase. Add Firebase when you want Google/Apple accounts to restore on another phone.

1. Create a Firebase project.
2. Android package / iOS bundle: `com.spendping.spendping`.
3. Download `google-services.json` → `android/app/`.
4. Download `GoogleService-Info.plist` → `ios/Runner/`.
5. Authentication: enable **Google** (and Apple on iOS). Add SHA-1/SHA-256 including Play App Signing.
6. Create a **Web client** OAuth ID and pass it as `GOOGLE_WEB_CLIENT_ID` at build time (see `docs/PLAY_STORE.md`).
7. On iOS, add the reversed client ID URL scheme from `GoogleService-Info.plist` (`REVERSED_CLIENT_ID`) to `CFBundleURLTypes`.
8. Firestore: production mode + `firebase/firestore.rules`.

Until those files exist, `FirebaseBootstrap.tryInit()` fails closed. Google Sign-In on Android still opens the account picker and stores the Google profile on this device.

## Where login and spends live

- **This phone:** Google email, name, and account id are in secure storage (`spendping.email`, `spendping.userId`). Spends live in SQLite (`spendping.sqlite`) keyed by that account id.
- **Cloud (needed to change phones):** Firestore `users/{uid}` holds the email; `users/{uid}/expenses` (and places, people, ledger, categories) hold the data. `emailLookups/{email}` points at the same `uid`.
- Spends are **not** stored under the email string as a database key (emails can change). They stay under the Google/Firebase uid, with the email saved on every synced row as `ownerEmail`.

On a new phone: sign in with the **same Google account** → same uid → sync pulls spends. This only works after Firebase is configured and Firestore rules from this folder are deployed.

Do not commit admin SDK keys or service-account JSON.
