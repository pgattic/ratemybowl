class Review {
  final BigInt restroomId;
  final String userId;
  final int stars;
  final DateTime reviewDt;
  final String notes;

  const Review({
    required this.restroomId,
    required this.userId,
    required this.stars,
    required this.reviewDt,
    required this.notes,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      restroomId: json['restroom_id'],
      userId: json['user_id'],
      stars: json['stars'],
      reviewDt: json['reivew_dt'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restroom_id': restroomId,
      'user_id': userId,
      'stars': stars,
      'review_dt': reviewDt,
      'notes': notes,
    };
  }
}
