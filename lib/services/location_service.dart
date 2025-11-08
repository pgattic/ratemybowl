import 'dart:async';
import 'package:location/location.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final Location _loc = Location();
  StreamSubscription<LocationData>? _sub;

  Future<void> configure() async {
    await _loc.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000,
      distanceFilter: 5,
    );
  }

  Future<bool> ensureReady() async {
    bool serviceEnabled = await _loc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _loc.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permission = await _loc.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _loc.requestPermission();
    }
    return permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited;
  }

  void startListening(void Function(LocationData) onData) {
    _sub?.cancel();
    _sub = _loc.onLocationChanged.listen(onData);
  }

  Future<LocationData> getOnce() async {
    return _loc.getLocation();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
