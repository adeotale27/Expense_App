# Privacy

SpendPing handles expenses, places, and people you add.

- Location is processed on-device. Optional Google Nearby Search uses the current stay to name a restaurant or pump; it does not upload a track.
- Raw GPS history is not synced.
- Cloud documents are scoped to `request.auth.uid`.
- Analytics events in a future build must not include coordinates or amounts.
- Export is available in More.
- Account/data deletion is available in More (device database). After Firebase is configured, also delete `users/{uid}` in Firestore (Cloud Function recommended for production).

See `docs/LOCATION_AND_NOTIFICATIONS.md`.
