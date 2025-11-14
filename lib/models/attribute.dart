import 'package:rate_my_bowl/models/attribute_definition.dart';
import 'package:rate_my_bowl/models/attribute_option.dart';
import 'package:rate_my_bowl/models/attribute_value_dto.dart';

class Attribute {
  final AttributeDefinition definition;
  final int restroomId;
  final int? reviewId;
  final Object value;

  const Attribute({
    required this.definition,
    required this.restroomId,
    this.reviewId,
    required this.value,
  }) : assert(
         value is bool ||
             value is num ||
             value is String ||
             value is AttributeOption,
         'value must be bool, num, String, or AttributeOption',
       );

  AttributeValueDto toDto() {
    bool? valueBool;
    int? valueInt;
    double? valueDecimal;
    String? valueText;
    int? valueOptionId;

    switch (definition.dataType) {
      case DataType.Bool:
        valueBool = value as bool;
        break;
      case DataType.Int:
        valueInt = value as int;
        break;
      case DataType.Decimal:
        valueDecimal = (value as num).toDouble();
        break;
      case DataType.Text:
        valueText = value as String;
        break;
      case DataType.Option:
        final opt = value as AttributeOption;
        valueOptionId = opt.optionId;
        break;
    }

    return AttributeValueDto(
      restroomId: restroomId,
      attrId: definition.attrId,
      reviewId: reviewId,
      valueBool: valueBool,
      valueInt: valueInt,
      valueDecimal: valueDecimal,
      valueText: valueText,
      valueOptionId: valueOptionId,
    );
  }
}
