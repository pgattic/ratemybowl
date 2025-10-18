import 'package:latlong2/latlong.dart';
import '../widgets/bathroom_pin.dart';

class BathroomLocation {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final List<BathroomType> bathroomTypes;
  final double rating;
  final int reviewCount;

  const BathroomLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.bathroomTypes,
    required this.rating,
    required this.reviewCount,
  });
}

class MockBathroomData {
  static List<BathroomLocation> getBathroomLocations() {
    return [
      // Joseph F. Smith Building - All three types
      const BathroomLocation(
        id: 'jfsb_ne',
        name: 'Joseph F Smith Building: North-East Restroom',
        description: 'Main restroom area with all facilities',
        coordinates: LatLng(40.24875188987069, -111.65141681875589),
        bathroomTypes: [BathroomType.men, BathroomType.women, BathroomType.other],
        rating: 4.5,
        reviewCount: 23,
      ),

      // Talmage Math Building - Men and Women
      const BathroomLocation(
        id: 'talmage_main',
        name: 'Talmage Math Building: Main Floor',
        description: 'Conveniently located near the main entrance',
        coordinates: LatLng(40.2495, -111.6505),
        bathroomTypes: [BathroomType.men, BathroomType.women],
        rating: 4.2,
        reviewCount: 15,
      ),

      // Talmage Math Building - Second floor
      const BathroomLocation(
        id: 'talmage_2nd',
        name: 'Talmage Math Building: Second Floor',
        description: 'Quiet restroom on the upper level',
        coordinates: LatLng(40.2497, -111.6503),
        bathroomTypes: [BathroomType.men, BathroomType.women],
        rating: 3.8,
        reviewCount: 8,
      ),

      // Library - Women only
      const BathroomLocation(
        id: 'library_women',
        name: 'Harold B. Lee Library: Women\'s Restroom',
        description: 'Clean and well-maintained facilities',
        coordinates: LatLng(40.2475, -111.6520),
        bathroomTypes: [BathroomType.women],
        rating: 4.7,
        reviewCount: 31,
      ),

      // Library - Men only
      const BathroomLocation(
        id: 'library_men',
        name: 'Harold B. Lee Library: Men\'s Restroom',
        description: 'Spacious men\'s facilities',
        coordinates: LatLng(40.2473, -111.6518),
        bathroomTypes: [BathroomType.men],
        rating: 4.3,
        reviewCount: 28,
      ),

      // Student Center - Men and Other
      const BathroomLocation(
        id: 'student_center',
        name: 'Student Center: Accessible Restroom',
        description: 'Gender-neutral and accessible facilities',
        coordinates: LatLng(40.2500, -111.6510),
        bathroomTypes: [BathroomType.men, BathroomType.other],
        rating: 4.6,
        reviewCount: 19,
      ),

      // Engineering Building - All three types
      const BathroomLocation(
        id: 'engineering_main',
        name: 'Engineering Building: Main Restroom',
        description: 'Modern facilities with all amenities',
        coordinates: LatLng(40.2480, -111.6500),
        bathroomTypes: [BathroomType.men, BathroomType.women, BathroomType.other],
        rating: 4.4,
        reviewCount: 22,
      ),

      // Marriott Center - Women and Other
      const BathroomLocation(
        id: 'marriott_center',
        name: 'Marriott Center: Event Restroom',
        description: 'Large capacity restrooms for events',
        coordinates: LatLng(40.2510, -111.6505),
        bathroomTypes: [BathroomType.women, BathroomType.other],
        rating: 3.9,
        reviewCount: 12,
      ),

      // Fine Arts Building - Other only
      const BathroomLocation(
        id: 'fine_arts',
        name: 'Fine Arts Building: Gender-Neutral Restroom',
        description: 'Inclusive facilities for all students',
        coordinates: LatLng(40.2470, -111.6515),
        bathroomTypes: [BathroomType.other],
        rating: 4.8,
        reviewCount: 16,
      ),

      // Heritage Halls - Men only
      const BathroomLocation(
        id: 'heritage_halls',
        name: 'Heritage Halls: Men\'s Dormitory Restroom',
        description: 'Residential hall facilities',
        coordinates: LatLng(40.2520, -111.6525),
        bathroomTypes: [BathroomType.men],
        rating: 3.5,
        reviewCount: 7,
      ),
    ];
  }
}
