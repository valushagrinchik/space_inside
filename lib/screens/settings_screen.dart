import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../core/tool_config.dart';
import 'notion_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final List<ToolConfig> tools;

  const SettingsScreen({super.key, required this.tools});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Set<String> _visible = {};
  Map<String, Set<String>> _visiblePractices = {};
  Future<void> _lastSave = Future.value();
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = widget.tools.map((t) => t.id).toList();
    final visible = await SettingsService.loadVisibleTools(ids);
    final visiblePractices = <String, Set<String>>{};
    for (final tool in widget.tools) {
      final practiceIds = (tool.practices ?? []).map((p) => p.id).toList();
      if (practiceIds.isNotEmpty) {
        visiblePractices[tool.id] = await SettingsService.loadVisiblePractices(
          tool.id,
          practiceIds,
        );
      }
    }
    setState(() {
      _visible = visible;
      _visiblePractices = visiblePractices;
    });
  }

  void _toggleTool(String id, bool value) {
    final updated = {..._visible};
    if (value) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    setState(() => _visible = updated);
    final save = SettingsService.saveVisibleTools(updated);
    _lastSave = Future.wait<void>([_lastSave, save]).then((_) {});
  }

  void _togglePractice(String toolId, String practiceId, bool value) {
    final updated = {..._visiblePractices[toolId]!};
    if (value) {
      updated.add(practiceId);
    } else {
      updated.remove(practiceId);
    }
    setState(() => _visiblePractices[toolId] = updated);
    final save = SettingsService.saveVisiblePractices(toolId, updated);
    _lastSave = Future.wait<void>([_lastSave, save]).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _popping,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _popping) return;
        await _lastSave;
        if (!mounted) return;
        setState(() => _popping = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop(result);
        });
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: ListView.builder(
          itemCount: widget.tools.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.tools.length) {
              final onSurface = Theme.of(context).colorScheme.onSurface;
              return ListTile(
                title: Text('Notion', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  'Настройки синхронизации',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotionSettingsScreen(),
                  ),
                ),
              );
            }
            final tool = widget.tools[index];
            final practices = tool.practices ?? [];
            final toolEnabled = _visible.contains(tool.id);
            if (practices.isEmpty) {
              return SwitchListTile(
                title: Text(
                  tool.name,
                  style: toolEnabled
                      ? null
                      : TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                ),
                value: toolEnabled,
                onChanged: (value) => _toggleTool(tool.id, value),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? null
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                inactiveTrackColor: Colors.transparent,
                trackOutlineColor: WidgetStateProperty.all(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(
                    tool.name,
                    style: toolEnabled
                        ? null
                        : TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                  ),
                  value: toolEnabled,
                  onChanged: (value) => _toggleTool(tool.id, value),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  inactiveTrackColor: Colors.transparent,
                  trackOutlineColor: WidgetStateProperty.all(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    children: practices.map((practice) {
                      final practiceEnabled =
                          _visiblePractices[tool.id]?.contains(practice.id) ??
                          false;
                      return SwitchListTile(
                        title: Text(
                          practice.title,
                          style: practiceEnabled
                              ? null
                              : TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                        ),
                        value: practiceEnabled,
                        onChanged: _visiblePractices[tool.id] == null
                            ? null
                            : (value) =>
                                  _togglePractice(tool.id, practice.id, value),
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? null
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        inactiveTrackColor: Colors.transparent,
                        trackOutlineColor: WidgetStateProperty.all(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
