# SpendPing

SpendPing is a local-first personal expense assistant for **iOS** and **Android**. It records expenses in a few seconds and can notice meaningful visits so it can ask:

> Did you spend anything here?

It does **not** invent expenses from GPS. A visit is only a prompt. You confirm the amount.

Current version: **1.0.0** (`VERSION` + `pubspec.yaml`).

## What works without Firebase

The app is fully usable offline on one device:

- Onboarding and local account
- Add / edit / delete expenses (SQLite)
- Home totals, history, search, filters
- Categories and payment methods
- People + borrow/lend ledger
- Places, visit engine, opportunities inbox
- Local notifications (when the OS allows them)
- Dark / light theme
- Data export
- Developer location simulator

Apple / Google sign-in and multi-device restore turn on after you add a Firebase project (`docs/FIREBASE.md`).

## Requirements

- Flutter **3.32+** / Dart **3.8+** (`flutter doctor`)
- Xcode 15+ for iOS
- Android Studio / SDK, minSdk **23**
- CocoaPods for iOS (`pod install` runs via `flutter run`)

## Clone and run

```bash
git clone <this-repo>
cd Expense_App   # or your checkout folder
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### iOS

```bash
cd ios && pod install && cd ..
flutter run -d ios
# or a simulator:
flutter devices
flutter run -d "iPhone"
```

Open `ios/Runner.xcworkspace` in Xcode to pick a signing team.

### Android

```bash
flutter run -d android
# or
flutter run -d emulator-5554
```

### Tests

```bash
flutter test
flutter analyze
```

## First-run path

1. Onboarding → **Continue on this device** (or email / Apple / Google when Firebase is configured).
2. Home → **Add Expense** → amount keypad → category → Save. Totals update immediately, including offline.
3. **More** → tap the title **seven times** → Developer → **Grocery 7m**. Then open **Expenses to review** (or Home banner).

## Version control files

| File | Role |
|---|---|
| `VERSION` | Marketing version `MAJOR.MINOR.PATCH` |
| `pubspec.yaml` `version` | `VERSION+build` used by iOS/Android |
| `CHANGELOG.md` | Human-readable history |

Bump both `VERSION` and `pubspec.yaml` together. Example: `1.0.1` and `1.0.1+2`.

## Project layout

```
lib/
  app/           theme, router, Riverpod
  domain/        entities, enums, repository contracts
  data/          Drift database, sync, Firebase adapters
  features/      UI
  location/      movement + opportunity engines (pure Dart)
  notifications/
test/            unit tests for money, ledger, visits, sync
docs/            architecture, schema, privacy, release
firebase/        Firestore security rules
```

## Hosting

There is no app server to rent for v1.

| Piece | Where |
|---|---|
| Mobile apps | App Store / Play Store |
| Auth + backup | Firebase Auth + Firestore (optional) |
| Privacy policy URL | Firebase Hosting / any static host |
| Push (optional) | FCM; most prompts are **local** notifications |

See `docs/RELEASE.md` and `docs/FIREBASE.md`.

## Platform notes

- iOS and Android share one Dart codebase. Location uses a `LocationProvider` adapter (`IOSLocationProvider` / `AndroidLocationProvider`) plus a simulator.
- Background location is best-effort. Missed visits still appear if the OS delivers a fix; otherwise use manual add + evening inbox.
- Do not poll GPS every few seconds. The production stream uses a **150m** distance filter.

## Known limitations

- Exact merchant names from reverse geocoding are often approximate.
- Short trips can be missed by the OS if Always location is denied.
- Firebase is optional; without it, data stays on the device.
- Widgets, App Intents, Watch, bank/GPay feeds are intentionally not in 1.0.0.
