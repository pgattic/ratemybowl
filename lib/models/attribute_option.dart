class AttributeOption {
  final int optionId;
  final int attrId;
  final String valueKey;
  final String displayName;

  const AttributeOption({
    required this.optionId,
    required this.attrId,
    required this.valueKey,
    required this.displayName,
  });

  factory AttributeOption.fromJson(Map<String, dynamic> json) {
    return AttributeOption(
      optionId: json['option_id'],
      attrId: json['attr_id'],
      valueKey: json['value_key'],
      displayName: json['display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_id': optionId,
      'attr_id': attrId,
      'value_key': valueKey,
      'display_name': displayName,
    };
  }
}
