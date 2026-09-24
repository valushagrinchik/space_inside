class PracticeConfig {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;

  const PracticeConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory PracticeConfig.fromJson(Map<String, dynamic> json) {
    return PracticeConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }
}

class ToolConfig {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? description;
  final List<PracticeConfig>? practices;

  const ToolConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description,
    this.practices,
  });

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      description: json['description'] as String?,
      practices: (json['practices'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map(PracticeConfig.fromJson)
          .toList(),
    );
  }
}
