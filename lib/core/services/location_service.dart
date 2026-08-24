import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService();

  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureType.servicesDisabled,
        'Location services are turned off. Turn on GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.permissionDenied,
        'Location permission was denied. You can try again or select a state manually.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.permissionDeniedForever,
        'Location permission is blocked. Enable it in app settings or select a state manually.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        LocationFailureType.servicesDisabled,
        'Location services were turned off. Turn on GPS and try again.',
      );
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureType.unavailable,
        'Your location could not be found in time. Move to an open area and try again.',
      );
    } catch (_) {
      throw const LocationFailure(
        LocationFailureType.unavailable,
        'Your location is unavailable right now. Try again or select a state manually.',
      );
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
