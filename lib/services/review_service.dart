import 'package:flutter/material.dart';
import 'package:rate_my_bowl/models/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._();
  ReviewService._();

  Future<List<Review>> getReviewsByRestroomId(int restroomId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_reviews_with_display_names',
        params: {'p_restroom_id': restroomId},
      );

      final List<Review> reviews = [];

      if (response != null) {
        for (var row in (response as List)) {
          reviews.add(Review.fromJson(row));
        }
      }

      return reviews;
    } catch (e) {
      debugPrint('Error fetching reviews by restroom id: $e');
      return [];
    }
  }

  Future<void> addReview(Review review) async {
    try {
      await Supabase.instance.client.from('review').insert(review.toJson());
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }
}
