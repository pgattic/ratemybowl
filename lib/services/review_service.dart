import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/review.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._();
  ReviewService._();
  final BackendAdapter _backend = backendAdapter;

  Future<List<Review>> getReviewsByRestroomId(int restroomId) async {
    try {
      return await _backend.getReviewsByRestroomId(restroomId);
    } catch (e) {
      debugPrint('Error fetching reviews by restroom id: $e');
      return [];
    }
  }

  Future<void> addReview(Review review) async {
    try {
      await _backend.addReview(review);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }
}
