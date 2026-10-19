import 'dart:developer';
import 'package:flutter/material.dart';
import '../core/l10n.dart';
import '../core/notion_service.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  bool _autoSync = false;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await NotionService.loadConfig();
    setState(() {
      _autoSync = config.autoSync;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await NotionService.saveConfig(NotionConfig(autoSync: _autoSync));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.t('settings_saved'))));
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final count = await NotionService.syncAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.fmt('synced_count', {'count': '$count'})),
        ),
      );
    } catch (e, stack) {
      log('Notion sync error: $e');
      log('$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(S.fmt('sync_error', {'error': '$e'}))),
      );
    } finally {
      setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.t('notion_env_hint'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              S.t('autosync_on_save'),
              style: TextStyle(color: onSurface),
            ),
            value: _autoSync,
            onChanged: (value) => setState(() => _autoSync = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: Text(S.t('save_settings')),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _syncing ? null : _syncNow,
            child: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.t('sync_now')),
          ),
        ],
      ),
    );
  }
}
