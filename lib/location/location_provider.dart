import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    this.accuracy = 25,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
}

abstract class LocationProvider {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  Future<GeoFix?> getCurrentLocation();
  Stream<GeoFix> get fixes;
}

class SimulatedLocationProvider implements LocationProvider {
  final _controller = StreamController<GeoFix>.broadcast();
  GeoFix? _last;

  @override
  Stream<GeoFix> get fixes => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> startMonitoring() async {}

  @override
  Future<void> stopMonitoring() async {}

  @override
  Future<GeoFix?> getCurrentLocation() async => _last;

  void emit(GeoFix fix) {
    _last = fix;
    if (!_controller.isClosed) _controller.add(fix);
  }

  void dispose() => _controller.close();
}

/// iOS: significant-change + visits via Geolocator distanceFilter.
/// Android: same fused-location API with a large distance filter.
/// Never polls every few seconds.
class PlatformLocationProvider implements LocationProvider {
  StreamSubscription<Position>? _sub;
  final _controller = StreamController<GeoFix>.broadcast();

  @override
  Stream<GeoFix> get fixes => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted || status.isLimited;
  }

  @override
  Future<bool> requestPermission() async {
    final whenInUse = await Permission.locationWhenInUse.request();
    if (!whenInUse.isGranted && !whenInUse.isLimited) return false;
    await Permission.locationAlways.request();
    return true;
  }

  @override
  Future<GeoFix?> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return GeoFix(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      timestamp: pos.timestamp,
    );
  }

  @override
  Future<void> startMonitoring() async {
    await _sub?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 150,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen((p) {
      _controller.add(
        GeoFix(
          latitude: p.latitude,
          longitude: p.longitude,
          accuracy: p.accuracy,
          timestamp: p.timestamp,
        ),
      );
    });
  }

  @override
  Future<void> stopMonitoring() async {
    await _sub?.cancel();
    _sub = null;
  }
}

class IOSLocationProvider extends PlatformLocationProvider {}

class AndroidLocationProvider extends PlatformLocationProvider {}
