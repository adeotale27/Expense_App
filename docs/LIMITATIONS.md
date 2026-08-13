# SpendPing — platform limitations

- iOS CLVisit / significant-change can delay or skip short stops.
- Android OEM battery savers can pause background location.
- Geolocator distanceFilter is a reliable cross-platform stand-in; native CLVisit / Android Geofencing can be added behind the same LocationProvider later.
- Reverse geocoding is not wired as a blocking network call in v1; developer catalog + learned places supply names. Hook `geocoding` in PlaceResolver when you want live POI labels (cache locally).
- Sign in with Apple is required by Apple if Google sign-in is offered in production.
