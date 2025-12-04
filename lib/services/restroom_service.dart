import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final filterFemale = prefs.getBool('filter_female') ?? false;
      final filterMale = prefs.getBool('filter_male') ?? false;
      final filterUnisex = prefs.getBool('filter_unisex') ?? false;
      final minRating = prefs.getDouble('filter_min_rating') ?? 0.0;

      final hasGenderFilter = filterFemale || filterMale || filterUnisex;
      final hasRatingFilter = minRating > 0.0;

      return await _backend.getRestroomLocations(
        lat: lat,
        lng: lng,
        radius: radius,
        filterFemale: hasGenderFilter ? filterFemale : null,
        filterMale: hasGenderFilter ? filterMale : null,
        filterUnisex: hasGenderFilter ? filterUnisex : null,
        minRating: hasRatingFilter ? minRating : null,
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
