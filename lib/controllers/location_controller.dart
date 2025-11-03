import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:rate_my_bowl/services/location_service.dart';

enum LocStatus { idle, checking, ready, denied, error }

class LocationController extends ChangeNotifier {
  LocStatus status = LocStatus.idle;
  LatLng? userLatLong;
  double? accuracy;
  String? error;
  bool _listening = false;

  Future<void> init() async {
    status = LocStatus.checking;
    notifyListeners();

    try {
      final ok = await LocationService.instance.ensureReady();
      if (!ok) {
        status = LocStatus.denied;
        notifyListeners();
        return;
      }

      await LocationService.instance.configure();
      final initLoc = await LocationService.instance.getOnce();

      _apply(initLoc);
      status = LocStatus.ready;
      notifyListeners();

      _start();
    } catch (e) {
      error = e.toString();
      status = LocStatus.error;
      notifyListeners();
    }
  }

  void _start() {
    if (_listening) return;
    _listening = true;

    LocationService.instance.startListening((loc) {
      _apply(loc);
      if (status != LocStatus.ready) {
        status = LocStatus.ready;
      }
      notifyListeners();
    });
  }

  void _apply(LocationData data) {
    final lat = data.latitude;
    final long = data.longitude;
    if (lat != null && long != null) {
      userLatLong = LatLng(lat, long);
      accuracy = data.accuracy;
    }
  }

  Future<void> disposeController() async {
    await LocationService.instance.stop();
    _listening = false;
  }
}
