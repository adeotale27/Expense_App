# Database schema

Local engine: Drift / SQLite file `spendping.sqlite` in app documents.

## Tables

- `expenses` — amount stored as integer minor units (paise for INR)
- `categories`
- `places`
- `people`
- `ledger_entries` — append-only events; balances are computed
- `opportunities`
- `recurring_expenses`
- `settings_rows` — JSON document per user
- `local_accounts` — offline email auth when Firebase is absent
- `raw_location_points` — short-lived, not synced

Indexes: `expenses(user_id, timestamp)`, `expenses(user_id, category_id)`, `ledger_entries(person_id, date)`.

Cloud (optional Firestore):

```
users/{userId}/expenses/{id}
users/{userId}/categories/{id}
users/{userId}/places/{id}
users/{userId}/people/{id}
users/{userId}/ledger/{id}
users/{userId}/recurringExpenses/{id}
users/{userId}/settings/{id}
```

Never store a GPS trace collection.
