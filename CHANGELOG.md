# Changelog

All notable changes to SpendPing are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

App version is sourced from:

- `VERSION` — marketing version (`MAJOR.MINOR.PATCH`)
- `pubspec.yaml` `version` — `VERSION+BUILD` (currently `1.0.0+1`)

## [1.0.0] — 2026-08-13

### Added

- Local-first expense tracking with Drift/SQLite
- Quick add flow (amount → category → save)
- Home dashboard with today / month totals and activity timeline
- Categories, payment methods, search, filters, and expense editing
- People and borrow/lend ledger with running balances
- Places, visit detection, opportunity engine, and pending inbox
- Smart local notifications with cooldown and daily limits
- Offline-first sync engine with optional Firebase (Auth + Firestore)
- Onboarding, dark/light theme, settings, privacy controls, data export
- Developer mode with location visit simulator
- Unit tests for expenses, ledger, location, prompts, and sync
- iOS and Android permission and background-location configuration
