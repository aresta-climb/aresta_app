import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  bool isLocationServiceEnabledResult = true;
  LocationPermission checkPermissionResult = LocationPermission.always;
  LocationPermission requestPermissionResult = LocationPermission.always;
  Position? currentPositionResult;
  Position? lastKnownPositionResult;
  Exception? currentPositionException;

  @override
  Future<bool> isLocationServiceEnabled() async => isLocationServiceEnabledResult;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult;

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async =>
      lastKnownPositionResult;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (currentPositionException != null) {
      throw currentPositionException!;
    }
    if (currentPositionResult != null) {
      return currentPositionResult!;
    }
    return Position(
      latitude: -20.0,
      longitude: -44.0,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 1000.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6378137.0; // metros
    final double dLat = _toRadians(endLatitude - startLatitude);
    final double dLon = _toRadians(endLongitude - startLongitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLatitude)) *
            math.cos(_toRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}
