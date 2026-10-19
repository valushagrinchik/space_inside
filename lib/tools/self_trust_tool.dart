import 'package:flutter/material.dart';
import '../core/journal_service.dart';
import '../core/l10n.dart';
import '../core/notion_service.dart';
import '../models/journal_entry.dart';
import 'journal/journal_wizard.dart';

class SelfTrustTool extends StatefulWidget {
  const SelfTrustTool({super.key});

  @override
  State<SelfTrustTool> createState() => _SelfTrustToolState();
}

class _SelfTrustToolState extends State<SelfTrustTool> {
  List<JournalEntry> _entries = [];
  bool _loading = true;

  static List<JournalStep> get _steps => [
    JournalStep(key: 'situation', prompt: S.t('st_situation')),
    JournalStep(key: 'selfSignal', prompt: S.t('st_self_signal')),
    JournalStep(key: 'chosenAction', prompt: S.t('st_chosen_action')),
    JournalStep(key: 'alternative', prompt: S.t('st_alternative')),
    JournalStep(key: 'feelingsAfter', prompt: S.t('st_feelings_after')),
    JournalStep(key: 'insight', prompt: S.t('st_insight')),
    JournalStep(
      key: 'difficulty',
      prompt: S.t('st_difficulty'),
      inputType: JournalInputType.slider,
      min: 0,
      max: 10,
      divisions: 10,
      label: S.t('st_difficulty_label'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.loadEntries('self_trust');
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
        practiceId: 'self_trust',
        toolId: 'selfkind',
        createdAt: createdAt,
        fields: result,
      ),
    );
    await NotionService.onEntrySaved(
      JournalEntry(
        id: id,
        practiceId: 'self_trust',
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
    final difficulty = (entry.fields['difficulty'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.fields['situation']?.toString() ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${S.t('field_difficulty')}: $difficulty/10 · ${_formatDate(entry.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Divider(height: 24),
            for (final key
                in _steps
                    .where((s) => s.inputType == JournalInputType.text)
                    .map((s) => s.key))
              _EntryField(
                title: _stepTitle(key),
                value: entry.fields[key]?.toString() ?? '',
              ),
            _EntryField(
              title: S.t('field_difficulty'),
              value: '$difficulty/10',
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(String key) {
    switch (key) {
      case 'situation':
        return S.t('field_situation');
      case 'selfSignal':
        return S.t('field_self_signal');
      case 'chosenAction':
        return S.t('field_chosen_action');
      case 'alternative':
        return S.t('field_alternative');
      case 'feelingsAfter':
        return S.t('field_feelings_after');
      case 'insight':
        return S.t('field_insight');
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
      appBar: AppBar(title: Text(S.t('self_trust'))),
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
