class ToolConfig {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? description;

  const ToolConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description,
  });

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      description: json['description'] as String?,
    );
  }
}
