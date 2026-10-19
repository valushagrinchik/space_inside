import 'package:flutter/material.dart';
import '../core/journal_service.dart';
import '../core/l10n.dart';
import '../core/notion_service.dart';
import '../models/journal_entry.dart';
import 'journal/journal_wizard.dart';

class GratitudeTool extends StatefulWidget {
  const GratitudeTool({super.key});

  @override
  State<GratitudeTool> createState() => _GratitudeToolState();
}

class _GratitudeToolState extends State<GratitudeTool> {
  List<JournalEntry> _entries = [];
  bool _loading = true;

  static List<JournalStep> get _steps => [
    JournalStep(key: 'moment', prompt: S.t('gratitude_moment')),
    JournalStep(key: 'source', prompt: S.t('gratitude_source')),
    JournalStep(key: 'reason', prompt: S.t('gratitude_reason')),
    JournalStep(key: 'impact', prompt: S.t('gratitude_impact')),
    JournalStep(key: 'feelings', prompt: S.t('gratitude_feelings')),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.loadEntries('gratitude');
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            JournalWizard(title: S.t('new_entry'), steps: _steps),
      ),
    );
    if (result == null) return;
    final createdAt = DateTime.now();
    final id = await JournalService.saveEntry(
      JournalEntry(
        practiceId: 'gratitude',
        toolId: 'selfkind',
        createdAt: createdAt,
        fields: result,
      ),
    );
    await NotionService.onEntrySaved(
      JournalEntry(
        id: id,
        practiceId: 'gratitude',
        toolId: 'selfkind',
        createdAt: createdAt,
        fields: result,
      ),
    );
    _load();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.fields['moment']?.toString() ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(entry.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Divider(height: 24),
            for (final key in _steps.map((s) => s.key))
              _EntryField(
                title: _stepTitle(key),
                value: entry.fields[key]?.toString() ?? '',
              ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(String key) {
    switch (key) {
      case 'moment':
        return S.t('field_moment');
      case 'source':
        return S.t('field_source');
      case 'reason':
        return S.t('field_reason');
      case 'impact':
        return S.t('field_impact');
      case 'feelings':
        return S.t('field_feelings');
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(S.t('gratitude'))),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Text(
                S.t('empty_entries'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) => _buildEntryCard(_entries[index]),
            ),
    );
  }
}

class _EntryField extends StatelessWidget {
  final String title;
  final String value;

  const _EntryField({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: onSurface),
          ),
        ],
      ),
    );
  }
}
