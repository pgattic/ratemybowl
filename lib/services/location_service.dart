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
      if (!serviceEnabled) return false;
    }

    PermissionStatus permission = await _loc.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _loc.requestPermission();
    }

    return permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited;
  }

  Future<bool> startListening(void Function(LocationData) onData) async {
    // Ensure service/permission before listening
    if (!await ensureReady()) return false;
    await configure();

    if (_sub != null) {
      await _sub!.cancel();
      _sub = null;
    }

    _sub = _loc.onLocationChanged.listen(
      (data) {
        // Optionally guard against null lat/lng
        if (data.latitude != null && data.longitude != null) {
          onData(data);
        }
      },
      onError: (e) {
        // Add logging here if you have a logger
        // debugPrint('Location stream error: $e');
      },
    );

    return true;
  }

  Future<LocationData> getOnce({Duration timeout = const Duration(seconds: 10)}) async {
    if (!await ensureReady()) {
      throw StateError('Location service not enabled or permission not granted.');
    }
    await configure();

    // 1) Try immediate/last-known location (fast path)
    try {
      final first = await _loc.getLocation().timeout(const Duration(seconds: 2));
      if (first.latitude != null && first.longitude != null) return first;
    } catch (_) {
      // ignore and fall back to stream
    }

    // 2) Fall back: wait for first emitted update (real GPS fix)
    final completer = Completer<LocationData>();
    late final StreamSubscription<LocationData> sub;

    sub = _loc.onLocationChanged.listen(
      (data) {
        if (!completer.isCompleted &&
            data.latitude != null &&
            data.longitude != null) {
          completer.complete(data);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
