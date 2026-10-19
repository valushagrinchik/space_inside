import 'package:flutter/material.dart';
import '../core/l10n.dart';
import '../core/settings_service.dart';
import '../core/tool_config.dart';
import 'notion_settings_screen.dart';
import 'tools_visibility_screen.dart';

class SettingsScreen extends StatelessWidget {
  final List<ToolConfig> tools;

  const SettingsScreen({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('settings'))),
      body: ListView(
        children: [
          ListTile(
            title: Text(S.t('language'), style: TextStyle(color: onSurface)),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'ru', label: Text('RU')),
              ],
              selected: {S.language.value},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final lang = selection.first;
                S.language.value = lang;
                SettingsService.saveLanguage(lang);
              },
            ),
          ),
          ListTile(
            title: Text(
              S.t('tools_visibility'),
              style: TextStyle(color: onSurface),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ToolsVisibilityScreen(tools: tools),
              ),
            ),
          ),
          ListTile(
            title: Text('Notion', style: TextStyle(color: onSurface)),
            subtitle: Text(
              S.t('notion_sync_settings'),
              style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotionSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
