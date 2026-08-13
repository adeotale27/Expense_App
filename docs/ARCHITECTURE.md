# SpendPing architecture

SpendPing is a local-first Flutter app. The phone is the source of truth for the UI. Firebase is an optional sync and auth backend.

```
Presentation (screens, Riverpod)
        ↓
Domain (entities, scoring, ledger math)
        ↓
Data (Drift repositories, sync engine)
        ↓
SQLite (always)     Firestore (when configured)
```

Location processing is on-device. Raw GPS is not uploaded. Opportunities are created only after a visit heuristic passes a configurable confidence threshold. An expense is never created from a visit alone.

## Platforms

- iOS: `IOSLocationProvider` via Geolocator significant-distance stream (`distanceFilter: 150m`)
- Android: same fused location API, background location permission declared
- Simulator: developer tools inject `GeoFix` events into the same engine

## Sync

Every synced row has `id`, `updatedAt`, `deletedAt`, `deviceId`, `version`, `syncStatus`.
Expenses and ledger rows are identity-based (UUID). Conflicts use latest `updatedAt`.
Duplicates are prevented because the primary key is the client-generated UUID.
