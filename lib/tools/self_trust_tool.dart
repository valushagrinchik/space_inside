import 'package:flutter/material.dart';
import '../core/journal_service.dart';
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

  static const _steps = [
    JournalStep(key: 'situation', prompt: '🖊 Коротко опиши ситуацию.'),
    JournalStep(
      key: 'selfSignal',
      prompt:
          '🫂 Что внутри подсказало тебе это решение? Какие мысли, чувства или телесные ощущения ты заметил(а)?',
    ),
    JournalStep(key: 'chosenAction', prompt: '✨ Что ты выбрал(а) сделать?'),
    JournalStep(
      key: 'alternative',
      prompt:
          '🌿 А как ты обычно поступил(а) бы в похожей ситуации или чего от тебя ожидали другие?',
    ),
    JournalStep(
      key: 'feelingsAfter',
      prompt: '🌱 Что ты почувствовал(а) после?',
    ),
    JournalStep(
      key: 'insight',
      prompt: '💭 Что эта ситуация показала тебе о себе?',
    ),
    JournalStep(
      key: 'difficulty',
      prompt:
          '⚡️ Насколько было сложно поступить так, а не по-другому? Оцени от 0 до 10.',
      inputType: JournalInputType.slider,
      min: 0,
      max: 10,
      divisions: 10,
      label: 'Проведи ползунок или нажми нужное число',
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
            const JournalWizard(title: 'Новая запись', steps: _steps),
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
              'Сложность: $difficulty/10 · ${_formatDate(entry.createdAt)}',
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
            _EntryField(title: 'Сложность', value: '$difficulty/10'),
          ],
        ),
      ),
    );
  }

  String _stepTitle(String key) {
    switch (key) {
      case 'situation':
        return 'Ситуация';
      case 'selfSignal':
        return 'Внутренний сигнал';
      case 'chosenAction':
        return 'Выбранное действие';
      case 'alternative':
        return 'Альтернатива';
      case 'feelingsAfter':
        return 'Чувства после';
      case 'insight':
        return 'Инсайт';
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
      appBar: AppBar(title: const Text('Self-trust')),
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
