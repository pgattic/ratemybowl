import 'package:rate_my_bowl/models/app_user.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/models/review.dart';

abstract class BackendAdapter {
  Future<void> initialize();

  Stream<AppUser?> get authStateChanges;
  Future<AppUser?> getCurrentUser();
  Future<AppUser?> signIn(String email, String password);
  Future<void> signOut();
  Future<AppUser?> signUp(String email, String username, String password);

  Future<List<Restroom>> getRestroomLocations({
    required double lat,
    required double lng,
    required double radius,
    bool? filterFemale,
    bool? filterMale,
    bool? filterUnisex,
    double? minRating,
    required bool minRatingEnabled,
  });

  Future<Restroom?> getRestroomById(int id);
  Future<Restroom> addRestroom(Restroom restroom);

  Future<List<Review>> getReviewsByRestroomId(int restroomId);
  Future<void> addReview(Review review);

  Future<Map<int, double>> getAttributeAveragesByRestroomId(int restroomId);
}
