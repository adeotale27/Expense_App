# Location and notifications

## Why we ask

SpendPing uses location to notice that you visited a grocery store or petrol pump, then asks: “Did you spend anything?” It does not assume you spent money.

## What we store

On device: places you name or that the app learns, visit duration, opportunity records.
Not uploaded by default: raw latitude/longitude streams.

## If you deny location

The app stays fully usable: add expenses, analytics, people/ledger, search.

## If you deny notifications

Opportunities still appear in **More → Expenses to review**.

## iOS

Enable Location (When In Use, then Always if you want background visit detection) and Notifications in Settings.

Background mode `location` is declared. App Review notes should explain this is for visit-based expense reminders, not tracking.

## Android

Foreground/background location and `POST_NOTIFICATIONS` (API 33+) are declared. Some OEMs restrict background location; evening review and the in-app inbox cover missed visits.

## Simulator

More → tap the title 7 times → Developer. Run Grocery 7m, Milk 4m, Pass restaurant, Office 8h.
