import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestroomService {
  static final RestroomService instance = RestroomService._();
  RestroomService._();

  Future<List<Restroom>> getRestroomLocations({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_restrooms_within_radius',
        params: {'center_lat': lat, 'center_lng': lng, 'radius_meters': radius},
      );

      final List<Restroom> restrooms = [];

      if (response != null) {
        for (var row in (response as List)) {
          double? latitude;
          double? longitude;

          // Extract coordinates
          if (row['lat'] != null && row['lng'] != null) {
            latitude = (row['lat'] as num).toDouble();
            longitude = (row['lng'] as num).toDouble();
          } else {
            final coordinates = row['coordinates'];
            if (coordinates != null) {
              if (coordinates is Map) {
                latitude = (coordinates['lat'] ?? coordinates['latitude'])
                    ?.toDouble();
                longitude =
                    (coordinates['lng'] ??
                            coordinates['longitude'] ??
                            coordinates['lon'])
                        ?.toDouble();
              } else if (coordinates is String) {
                final match = RegExp(
                  r'POINT\(([-\d.]+)\s+([-\d.]+)\)',
                ).firstMatch(coordinates);
                if (match != null) {
                  longitude = double.tryParse(match.group(1)!);
                  latitude = double.tryParse(match.group(2)!);
                }
              }
            }
          }

          if (latitude == null || longitude == null) {
            continue;
          }

          final avgRating = row['avg_rating'];
          final rating = avgRating != null
              ? (avgRating as num).toDouble()
              : 0.0;

          final reviewCount = row['review_count'];
          final count = reviewCount != null ? (reviewCount as num).toInt() : 0;

          final gender = Restroom.getGender(row['gender'] ?? 0);

          final attributesData = row['attributes'];
          final List<String> attributes = [];
          if (attributesData != null) {
            if (attributesData is List) {
              attributes.addAll(attributesData.map((e) => e.toString()));
            } else if (attributesData is String) {
              attributes.addAll(attributesData.split(',').map((e) => e.trim()));
            }
          }

          final restroomId = row['restroom_id'];

          restrooms.add(
            Restroom(
              id: restroomId,
              name: row['name'] ?? 'Unnamed Restroom',
              coordinates: LatLng(latitude, longitude),
              gender: gender,
              rating: rating,
              reviewCount: count,
              attributes: attributes,
            ),
          );
        }
      }

      return restrooms;
    } catch (e) {
      debugPrint('Error fetching restroom locations: $e');
      return [];
    }
  }

  Future<Restroom?> getRestroomById(String id) async {
    try {
      final response = await Supabase.instance.client
          .from('restroom')
          .select('*')
          .eq('id', id)
          .single();
      return Restroom.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching restroom by id: $e');
      return null;
    }
  }

  Future<Restroom> addRestroom(Restroom restroom) async {
    try {
      final data = restroom.toJson();
      // We don't want to set the restroom_id - let the database generate it automatically for us, otherwise we'll get an error
      data.remove('restroom_id');
      
      final response = await Supabase.instance.client
          .from('restroom')
          .insert(data)
          .select()
          .single();

      final restroomId = response['restroom_id'];
      return Restroom(
        id: restroomId is int ? restroomId : (restroomId is num ? restroomId.toInt() : null),
        name: response['name'] ?? restroom.name,
        coordinates: restroom.coordinates,
        gender: restroom.gender,
        rating: 0.0,
        reviewCount: 0,
        attributes: [],
      );
    } catch (e) {
      debugPrint('Error adding restroom: $e');
      rethrow;
    }
  }
}
