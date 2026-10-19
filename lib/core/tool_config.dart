import 'l10n.dart';

class PracticeConfig {
  final String id;
  final String title;
  final String? titleRu;
  final String description;
  final String? descriptionRu;
  final String icon;
  final String color;

  const PracticeConfig({
    required this.id,
    required this.title,
    this.titleRu,
    required this.description,
    this.descriptionRu,
    required this.icon,
    required this.color,
  });

  String get displayTitle =>
      S.language.value == 'ru' ? (titleRu ?? title) : title;

  String get displayDescription =>
      S.language.value == 'ru' ? (descriptionRu ?? description) : description;

  factory PracticeConfig.fromJson(Map<String, dynamic> json) {
    return PracticeConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      titleRu: json['title_ru'] as String?,
      description: json['description'] as String,
      descriptionRu: json['description_ru'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }
}

class ToolConfig {
  final String id;
  final String name;
  final String? nameRu;
  final String icon;
  final String color;
  final String? description;
  final String? descriptionRu;
  final List<PracticeConfig>? practices;
  final bool hideTitle;

  const ToolConfig({
    required this.id,
    required this.name,
    this.nameRu,
    required this.icon,
    required this.color,
    this.description,
    this.descriptionRu,
    this.practices,
    this.hideTitle = false,
  });

  String get displayName => S.language.value == 'ru' ? (nameRu ?? name) : name;

  String? get displayDescription => S.language.value == 'ru'
      ? (descriptionRu ?? description)
      : description;

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['name_ru'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      description: json['description'] as String?,
      descriptionRu: json['description_ru'] as String?,
      practices: (json['practices'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map(PracticeConfig.fromJson)
          .toList(),
      hideTitle: json['hide_title'] == true,
    );
  }
}
