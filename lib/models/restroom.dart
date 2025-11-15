//restroom model has, name, coordinates, gender, rating, review count, attributes

import 'package:latlong2/latlong.dart';

enum Gender { Male, Female, Unisex }

class Restroom {
  final int? id;
  final String name;
  final LatLng coordinates;
  final Gender gender;
  final double rating;
  final int reviewCount;
  final List<String> attributes;

  const Restroom({
    this.id,
    required this.name,
    required this.coordinates,
    required this.gender,
    required this.rating,
    required this.reviewCount,
    required this.attributes,
  });

  factory Restroom.fromJson(Map<String, dynamic> json) {
    return Restroom(
      id: json['restroom_id'],
      name: json['name'],
      coordinates: LatLng(
        json['coordinates']['lat'],
        json['coordinates']['lng'],
      ),
      gender: getGender(json['gender']),
      rating: json['rating'],
      reviewCount: json['review_count'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    // For database insert, only include fields that exist in the restroom table
    // coordinate is a PostGIS geography type
    // Supabase may accept the POINT string format, or we may need to use an RPC function
    return {
      'name': name,
      'coordinate': 'SRID=4326;POINT(${coordinates.longitude} ${coordinates.latitude})',
      'gender': genderInt,
    };
  }

  static Gender getGender(int genderInt) {
    return switch (genderInt) {
      0 => Gender.Unisex,
      1 => Gender.Male,
      2 => Gender.Female,
      _ => throw ArgumentError("Unexpected Gender enum value: $genderInt"),
    };
  }

  int get genderInt {
    return switch (gender) {
      Gender.Unisex => 0,
      Gender.Male => 1,
      Gender.Female => 2,
    };
  }
}
