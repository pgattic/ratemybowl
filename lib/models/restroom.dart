//restroom model has, name, coordinates, gender, rating, review count, attributes

import 'package:latlong2/latlong.dart';

class Restroom {
  final String name;
  final LatLng coordinates;
  final String gender;
  final double rating;
  final int reviewCount;
  final List<String> attributes;

  const Restroom({
    required this.name,
    required this.coordinates,
    required this.gender,
    required this.rating,
    required this.reviewCount,
    required this.attributes,
  });

  factory Restroom.fromJson(Map<String, dynamic> json) {
    return Restroom(
      name: json['name'],
      coordinates: LatLng(
        json['coordinates']['lat'],
        json['coordinates']['lng'],
      ),
      gender: json['gender'],
      rating: json['rating'],
      reviewCount: json['review_count'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinates': coordinates.toString(),
      'gender': gender,
      'rating': rating,
      'reviewCount': reviewCount,
      'attributes': attributes,
    };
  }
}
