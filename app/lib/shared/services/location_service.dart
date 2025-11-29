import 'package:geolocator/geolocator.dart';

class LocationService {
  static const LocationSettings _defaultSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5,
  );

  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await ensureServiceAndPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _defaultSettings,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

