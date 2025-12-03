class Review {
  final int? reviewId;
  final int restroomId;
  final String userId;
  final int stars;
  final DateTime reviewDt;
  final String? notes;
  final String? displayName;

  const Review({
    this.reviewId,
    required this.restroomId,
    required this.userId,
    required this.stars,
    required this.reviewDt,
    this.notes,
    this.displayName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'],
      restroomId: json['restroom_id'],
      userId: json['user_id'],
      stars: json['stars'],
      reviewDt: DateTime.parse(json['review_dt']),
      notes: json['notes'] as String?,
      displayName: json['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restroom_id': restroomId,
      'user_id': userId,
      'stars': stars,
      'review_dt': reviewDt.toIso8601String(),
      'notes': notes,
    };
  }
}
