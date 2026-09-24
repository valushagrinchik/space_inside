import 'package:flutter/material.dart';
import '../core/journal_service.dart';
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

  static const _steps = [
    JournalStep(
      key: 'moment',
      prompt:
          '✨ Благодарность — это способ заметить хорошее, которое уже есть в твоей жизни.\n\n'
          '🖊 Вспомни один момент за сегодня, за который ты чувствуешь благодарность. Что произошло?',
    ),
    JournalStep(
      key: 'source',
      prompt:
          '🫂 Кому или чему ты благодарен(на) в этой ситуации? Это человек, действие, обстоятельство или ты сам(а)?',
    ),
    JournalStep(
      key: 'reason',
      prompt:
          '💡 Что именно в этом моменте вызвало твою благодарность? Почему это было важно для тебя?',
    ),
    JournalStep(
      key: 'impact',
      prompt:
          '🌱 Как этот момент повлиял на твой день или состояние? Что в тебе изменилось?',
    ),
    JournalStep(
      key: 'feelings',
      prompt:
          '🤍 Если описать твоё чувство сейчас — какое оно? (тепло, спокойствие, радость, облегчение и т.д.)',
    ),
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
            const JournalWizard(title: 'Новая запись', steps: _steps),
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
        return 'Момент';
      case 'source':
        return 'Источник';
      case 'reason':
        return 'Причина';
      case 'impact':
        return 'Влияние';
      case 'feelings':
        return 'Чувство';
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
      appBar: AppBar(title: const Text('Gratitude')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Text(
                'Пока нет записей. Нажми +, чтобы добавить.',
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
