import 'package:rate_my_bowl/models/attribute.dart';

class ReviewAttribute {
  final int reviewId;
  final int attributeId;
  final int rating;

  const ReviewAttribute({
    required this.reviewId,
    required this.attributeId,
    required this.rating,
  });

  Attribute? get attribute => Attribute.fromId(attributeId);

  factory ReviewAttribute.fromJson(Map<String, dynamic> json) {
    return ReviewAttribute(
      reviewId: json['review_id'] as int,
      attributeId: json['attribute_id'] as int,
      rating: json['rating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'attribute_id': attributeId,
      'rating': rating,
    };
  }
}
