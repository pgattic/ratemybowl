import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/restroom.dart';

class RestroomService {
  static final RestroomService instance = RestroomService._();
  RestroomService._();
  final BackendAdapter _backend = backendAdapter;

  Future<List<Restroom>> getRestroomLocations({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      return await _backend.getRestroomLocations(
        lat: lat,
        lng: lng,
        radius: radius,
      );
    } catch (e) {
      debugPrint('Error fetching restroom locations: $e');
      return [];
    }
  }

  Future<Restroom?> getRestroomById(int id) async {
    try {
      return await _backend.getRestroomById(id);
    } catch (e) {
      debugPrint('Error fetching restroom by id: $e');
      return null;
    }
  }

  Future<Restroom> addRestroom(Restroom restroom) async {
    try {
      return await _backend.addRestroom(restroom);
    } catch (e) {
      debugPrint('Error adding restroom: $e');
      rethrow;
    }
  }
}
