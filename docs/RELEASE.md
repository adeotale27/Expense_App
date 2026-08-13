# Release

Version source of truth:

- `VERSION` — `MAJOR.MINOR.PATCH`
- `pubspec.yaml` `version:` — `VERSION+BUILD` e.g. `1.0.0+1`
- `CHANGELOG.md`

## iOS

```bash
flutter build ipa --release
```

Upload via Xcode or Transporter. Enable Sign in with Apple if Google sign-in is offered.

## Android

```bash
flutter build appbundle --release
```

Replace debug signing in `android/app/build.gradle.kts` with an upload keystore before Play production.

## Checks

```bash
flutter test
flutter analyze
```
