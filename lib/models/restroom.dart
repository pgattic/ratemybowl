//restroom model has, name, coordinates, gender, rating, review count, attributes

import 'package:latlong2/latlong.dart';

enum Gender { Male, Female, Unisex }

class Restroom {
  final String name;
  final LatLng coordinates;
  final Gender gender;
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
      gender: getGender(json['gender']),
      rating: json['rating'],
      reviewCount: json['review_count'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinates': coordinates.toString(),
      'gender': genderInt,
      'rating': rating,
      'reviewCount': reviewCount,
      'attributes': attributes,
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
