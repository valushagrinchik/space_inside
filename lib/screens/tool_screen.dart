import 'package:flutter/material.dart';
import '../core/tool_config.dart';

class ToolScreen extends StatelessWidget {
  final ToolConfig config;
  final WidgetBuilder childBuilder;

  const ToolScreen({
    super.key,
    required this.config,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: childBuilder(context),
    );
  }
}
