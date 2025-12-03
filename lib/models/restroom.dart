//restroom model has, name, coordinates, gender, rating, review count, attributes

import 'package:latlong2/latlong.dart';

enum Gender { male, female, unisex }

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
    final idValue = json['restroom_id'] ?? json['id'];
    final nameValue = json['name'] ?? 'Unnamed Restroom';
    final coords = _parseCoordinates(json) ?? const LatLng(0, 0);
    final genderValue = json['gender'];
    final ratingValue = json['rating'] ?? json['avg_rating'] ?? 0;
    final reviewCountValue = json['review_count'] ?? json['reviews'] ?? 0;
    final attributesValue = json['attributes'];

    return Restroom(
      id: _asInt(idValue),
      name: nameValue as String,
      coordinates: coords,
      gender: getGender(_asInt(genderValue)),
      rating: _asDouble(ratingValue) ?? 0.0,
      reviewCount: _asInt(reviewCountValue) ?? 0,
      attributes: _parseAttributes(attributesValue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinate': 'SRID=4326;POINT(${coordinates.longitude} ${coordinates.latitude})',
      'gender': genderInt,
    };
  }

  static Gender getGender(int? genderInt) {
    switch (genderInt) {
      case 1:
        return Gender.male;
      case 2:
        return Gender.female;
      case 0:
      default:
        return Gender.unisex;
    }
  }

  int get genderInt {
    return switch (gender) {
      Gender.unisex => 0,
      Gender.male => 1,
      Gender.female => 2,
    };
  }

  static LatLng? _parseCoordinates(Map<String, dynamic> json) {
    final coordinates = json['coordinates'];
    if (coordinates is Map) {
      final lat = coordinates['lat'] ??
          coordinates['latitude'] ??
          coordinates['y'] ??
          coordinates['Y'];
      final lng = coordinates['lng'] ??
          coordinates['longitude'] ??
          coordinates['x'] ??
          coordinates['X'] ??
          coordinates['lon'];
      final latitude = _asDouble(lat);
      final longitude = _asDouble(lng);
      if (latitude != null && longitude != null) {
        return LatLng(latitude, longitude);
      }
    }

    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    final latitude = _asDouble(lat);
    final longitude = _asDouble(lng);
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }

    final coordinateString = json['coordinate'];
    if (coordinateString is String) {
      final normalized = coordinateString.contains(';')
          ? coordinateString.split(';').last
          : coordinateString;
      final match =
          RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(normalized);
      if (match != null) {
        final lon = double.tryParse(match.group(1)!);
        final latitude = double.tryParse(match.group(2)!);
        if (lon != null && latitude != null) {
          return LatLng(latitude, lon);
        }
      }
    }

    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _parseAttributes(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
