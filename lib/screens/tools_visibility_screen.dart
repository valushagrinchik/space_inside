import 'package:flutter/material.dart';
import '../core/l10n.dart';
import '../core/settings_service.dart';
import '../core/tool_config.dart';

class ToolsVisibilityScreen extends StatefulWidget {
  final List<ToolConfig> tools;

  const ToolsVisibilityScreen({super.key, required this.tools});

  @override
  State<ToolsVisibilityScreen> createState() => _ToolsVisibilityScreenState();
}

class _ToolsVisibilityScreenState extends State<ToolsVisibilityScreen> {
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

  Widget _switchTile({
    required String title,
    required bool enabled,
    required void Function(bool)? onChanged,
  }) {
    final dimmed = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);
    return SwitchListTile(
      title: Text(
        title,
        style: enabled ? null : TextStyle(color: dimmed),
      ),
      value: enabled,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? null : dimmed,
      ),
      inactiveTrackColor: Colors.transparent,
      trackOutlineColor: WidgetStateProperty.all(dimmed),
    );
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
        appBar: AppBar(title: Text(S.t('tools_visibility'))),
        body: ListView.builder(
          itemCount: widget.tools.length,
          itemBuilder: (context, index) {
            final tool = widget.tools[index];
            final practices = tool.practices ?? [];
            final toolEnabled = _visible.contains(tool.id);
            if (practices.isEmpty) {
              return _switchTile(
                title: tool.displayName,
                enabled: toolEnabled,
                onChanged: (value) => _toggleTool(tool.id, value),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _switchTile(
                  title: tool.displayName,
                  enabled: toolEnabled,
                  onChanged: (value) => _toggleTool(tool.id, value),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    children: practices.map((practice) {
                      final practiceEnabled =
                          _visiblePractices[tool.id]?.contains(practice.id) ??
                          false;
                      return _switchTile(
                        title: practice.displayTitle,
                        enabled: practiceEnabled,
                        onChanged: _visiblePractices[tool.id] == null
                            ? null
                            : (value) =>
                                  _togglePractice(tool.id, practice.id, value),
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
