import 'dart:developer';
import 'package:flutter/material.dart';
import '../core/notion_service.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final _tokenController = TextEditingController();
  final _databaseIdController = TextEditingController();
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
    _tokenController.text = config.token;
    _databaseIdController.text = config.databaseId;
    setState(() {
      _autoSync = config.autoSync;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await NotionService.saveConfig(
      NotionConfig(
        token: _tokenController.text.trim(),
        databaseId: _databaseIdController.text.trim(),
        autoSync: _autoSync,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final count = await NotionService.syncAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Синхронизировано записей: $count')),
      );
    } catch (e, stack) {
      log('Notion sync error: $e');
      log('$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка синхронизации: $e')));
    } finally {
      setState(() => _syncing = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _databaseIdController.dispose();
    super.dispose();
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
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Интеграционный токен Notion',
              border: OutlineInputBorder(),
            ),
            style: TextStyle(color: onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _databaseIdController,
            decoration: const InputDecoration(
              labelText: 'ID базы данных Notion',
              border: OutlineInputBorder(),
            ),
            style: TextStyle(color: onSurface),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Автосинхронизация при сохранении',
              style: TextStyle(color: onSurface),
            ),
            value: _autoSync,
            onChanged: (value) => setState(() => _autoSync = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Сохранить настройки'),
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
                : const Text('Синхронизировать сейчас'),
          ),
        ],
      ),
    );
  }
}
