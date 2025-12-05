class Attribute {
  final int id;
  final String displayName;
  final String icon;

  const Attribute({
    required this.id,
    required this.displayName,
    required this.icon,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'icon': icon,
    };
  }
}
