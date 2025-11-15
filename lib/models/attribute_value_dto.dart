class AttributeValueDto {
  final int restroomId;
  final int attrId;
  final int? reviewId;

  final bool? valueBool;
  final int? valueInt;
  final double? valueDecimal;
  final String? valueText;
  final int? valueOptionId;

  const AttributeValueDto({
    required this.restroomId,
    required this.attrId,
    this.reviewId,
    this.valueBool,
    this.valueInt,
    this.valueDecimal,
    this.valueText,
    this.valueOptionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'restroom_id': restroomId,
      'attr_id': attrId,
      'review_id': reviewId,
      'value_bool': valueBool,
      'value_int': valueInt,
      'value_decimal': valueDecimal,
      'value_text': valueText,
      'value_option_id': valueOptionId,
    };
  }

  factory AttributeValueDto.fromJson(Map<String, dynamic> json) {
    return AttributeValueDto(
      restroomId: json['restroom_id'] as int,
      attrId: json['attr_id'] as int,
      reviewId: json['review_id'] as int?,
      valueBool: json['value_bool'] as bool?,
      valueInt: json['value_int'] as int?,
      valueDecimal: (json['value_decimal'] as num?)?.toDouble(),
      valueText: json['value_text'] as String?,
      valueOptionId: json['value_option_id'] as int?,
    );
  }
}
