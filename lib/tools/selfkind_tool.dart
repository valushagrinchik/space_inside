import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../core/tool_config.dart';
import '../core/tool_icon.dart';
import '../core/tool_registry.dart';
import 'gratitude_tool.dart';
import 'self_trust_tool.dart';

class SelfKindTool extends StatelessWidget {
  const SelfKindTool({super.key});

  Future<_SelfKindData> _loadData() async {
    final tools = await ToolRegistry.load();
    final config = tools.firstWhere((t) => t.id == 'selfkind');
    final allIds = (config.practices ?? []).map((p) => p.id).toList();
    final visible = await SettingsService.loadVisiblePractices(
      'selfkind',
      allIds,
    );
    return _SelfKindData(config: config, visible: visible);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SelfKindData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final practices = snapshot.data!.config.practices ?? [];
        final visible = snapshot.data!.visible;
        final filtered = practices
            .where((p) => visible.contains(p.id))
            .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < filtered.length; i++) ...[
                _PracticeCard(
                  title: filtered[i].title,
                  description: filtered[i].description,
                  icon: resolveIcon(filtered[i].icon),
                  color: _hexColor(filtered[i].color),
                  onTap: () => _openPractice(context, filtered[i].id),
                ),
                if (i < filtered.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SelfKindData {
  final ToolConfig config;
  final Set<String> visible;
  const _SelfKindData({required this.config, required this.visible});
}

Color _hexColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

void _openPractice(BuildContext context, String id) {
  if (id == 'gratitude') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GratitudeTool()));
  } else if (id == 'self_trust') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SelfTrustTool()));
  }
}

class _PracticeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _PracticeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: onSurface),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
