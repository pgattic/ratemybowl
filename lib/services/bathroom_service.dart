import 'package:latlong2/latlong.dart';
import 'package:rate_my_bowl/models/bathroom_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BathroomService {
  static final BathroomService instance = BathroomService._();
  BathroomService._();

  Future<List<BathroomLocation>> getBathroomLocations({
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

      final List<BathroomLocation> bathrooms = [];
      
      if (response != null) {
        for (var row in (response as List)) {
          double? latitude;
          double? longitude;

          if (row['lat'] != null && row['lng'] != null) {
            latitude = (row['lat'] as num).toDouble();
            longitude = (row['lng'] as num).toDouble();
          } else {
            final coordinates = row['coordinates'];
            if (coordinates != null) {

              if (coordinates is Map) {
                latitude = (coordinates['lat'] ?? coordinates['latitude'])?.toDouble();
                longitude = (coordinates['lng'] ?? coordinates['longitude'] ?? coordinates['lon'])?.toDouble();
              } 

              else if (coordinates is String) {
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

          bathrooms.add(
            BathroomLocation(
              id: row['restroom_id'].toString(),
              name: row['name'] ?? 'Unnamed Restroom',
              description: '', 
              coordinates: LatLng(latitude, longitude),
              bathroomTypes: [], 
              rating: 0.0, 
              reviewCount: 0,
            ),
          );
        }
      }

      return bathrooms;
    } catch (e) {
      print('Error fetching bathroom locations: $e');

      return [];
    }
  }
}