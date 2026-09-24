import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tool_config.dart';
import '../tools/selfkind_tool.dart';
import '../tools/career_tool.dart';
import '../tools/moments_tool.dart';
import '../tools/reminders_tool.dart';
import '../tools/relationship_tool.dart';

class ToolRegistry {
  static final Map<String, WidgetBuilder> _builders = {
    'selfkind': (context) => const SelfKindTool(),
    'career': (context) => const CareerTool(),
    'moments': (context) => const MomentsTool(),
    'relationship': (context) => const RelationshipTool(),
    'reminders': (context) => const RemindersTool(),
  };

  static Future<List<ToolConfig>> load() async {
    final raw = await rootBundle.loadString('assets/tools.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['tools'] as List).cast<Map<String, dynamic>>();
    return list.map(ToolConfig.fromJson).toList();
  }

  static WidgetBuilder? builder(String id) => _builders[id];
}
