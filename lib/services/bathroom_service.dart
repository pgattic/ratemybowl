import 'package:latlong2/latlong.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BathroomService {
  static final BathroomService instance = BathroomService._();
  BathroomService._();

  Future<List<Restroom>> getBathroomLocations({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      
      final response = await Supabase.instance.client.rpc(
        'get_restrooms_within_radius',
        params: {
          'center_lat': lat,
          'center_lng': lng,
          'radius_meters': radius,
        },
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
                latitude = (coordinates['lat'] ?? coordinates['latitude'])?.toDouble();
                longitude = (coordinates['lng'] ?? coordinates['longitude'] ?? coordinates['lon'])?.toDouble();
              } else if (coordinates is String) {
                final match = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(coordinates);
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
          final rating = avgRating != null ? (avgRating as num).toDouble() : 0.0;
          
          final reviewCount = row['review_count'];
          final count = reviewCount != null ? (reviewCount as num).toInt() : 0;

          final gender = row['gender']?.toString() ?? '';

          final attributesData = row['attributes'];
          final List<String> attributes = [];
          if (attributesData != null) {
            if (attributesData is List) {
              attributes.addAll(attributesData.map((e) => e.toString()));
            } else if (attributesData is String) {
              attributes.addAll(attributesData.split(',').map((e) => e.trim()));
            }
          }

          restrooms.add(
            Restroom(
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
      print('Error fetching bathroom locations: $e');
      return [];
    }
  }

  Future<Restroom?> getRestroomById(String id) async {
    try {
      final response = await Supabase.instance.client.from('restrooms').select('*').eq('id', id).single();
        return Restroom.fromJson(response);
    } catch (e) {
      print('Error fetching restroom by id: $e');
      return null;
    }
  }

  Future<void> addRestroom(Restroom restroom) async {
    try {
      await Supabase.instance.client.from('restrooms').insert(restroom.toJson());
    } catch (e) {
      print('Error adding restroom: $e');
    }
  }
}

