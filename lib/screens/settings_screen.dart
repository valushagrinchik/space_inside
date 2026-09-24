import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../core/tool_config.dart';

class SettingsScreen extends StatefulWidget {
  final List<ToolConfig> tools;

  const SettingsScreen({super.key, required this.tools});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Set<String> _visible = {};
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
    setState(() => _visible = visible);
  }

  void _toggle(String id, bool value) {
    final updated = {..._visible};
    if (value) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    setState(() => _visible = updated);
    _lastSave = SettingsService.saveVisibleTools(updated);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _popping,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _popping) return;
        setState(() => _popping = true);
        await _lastSave;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(result);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: ListView.builder(
          itemCount: widget.tools.length,
          itemBuilder: (context, index) {
            final tool = widget.tools[index];
            return SwitchListTile(
              title: Text(tool.name),
              value: _visible.contains(tool.id),
              onChanged: (value) => _toggle(tool.id, value),
            );
          },
        ),
      ),
    );
  }
}
