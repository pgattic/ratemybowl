enum DataType { bool, int, decimal, text, option }

enum AppliesTo { restroom, review }

class AttributeDefinition {
  final int attrId;
  final String attrKey;
  final String displayName;
  final DataType dataType;
  final String? unit;
  final int? minValue;
  final int? maxValue;
  final AppliesTo appliesTo;

  const AttributeDefinition({
    required this.attrId,
    required this.attrKey,
    required this.displayName,
    required this.dataType,
    this.unit,
    this.minValue,
    this.maxValue,
    required this.appliesTo,
  });

  factory AttributeDefinition.fromJson(Map<String, dynamic> json) {
    return AttributeDefinition(
      attrId: json['attr_id'],
      attrKey: json['attr_key'],
      displayName: json['display_name'],
      dataType: getDataType(json['data_type']),
      unit: json['unit'],
      minValue: json['min_value'],
      maxValue: json['max_value'],
      appliesTo: getAppliesTo(json['applies_to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attr_id': attrId,
      'attr_key': attrKey,
      'display_name': displayName,
      'data_type': dataTypeString,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
      'applies_to': appliesToString,
    };
  }

  static DataType getDataType(String dtStr) {
    return switch (dtStr.toLowerCase()) {
      'bool' => DataType.bool,
      'int' => DataType.int,
      'decimal' => DataType.decimal,
      'text' => DataType.text,
      'option' => DataType.option,
      _ => throw ArgumentError("Unexpected DataType enum value: $dtStr"),
    };
  }

  static AppliesTo getAppliesTo(String applToStr) {
    return switch (applToStr.toLowerCase()) {
      'restroom' => AppliesTo.restroom,
      'review' => AppliesTo.review,
      _ => throw ArgumentError("Unexpected AppliesTo enum value: $applToStr"),
    };
  }

  String get dataTypeString {
    return switch (dataType) {
      DataType.bool => 'bool',
      DataType.int => 'int',
      DataType.decimal => 'decimal',
      DataType.text => 'text',
      DataType.option => 'option',
    };
  }

  String get appliesToString {
    return switch (appliesTo) {
      AppliesTo.restroom => 'restroom',
      AppliesTo.review => 'review',
    };
  }
}
