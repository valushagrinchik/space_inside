import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/journal_service.dart';
import '../core/l10n.dart';
import '../models/journal_entry.dart';

class MoodTool extends StatefulWidget {
  const MoodTool({super.key});

  @override
  State<MoodTool> createState() => _MoodToolState();
}

class _MoodToolState extends State<MoodTool> {
  List<JournalEntry> _entries = [];
  bool _loading = true;
  DateTime _selectedDay = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasEntry(DateTime day) =>
      _entries.any((e) => _sameDay(e.createdAt.toLocal(), day));

  bool _isToday(DateTime day) => _sameDay(day, DateTime.now());

  bool _isEnabled(DateTime day) =>
      !day.isAfter(DateTime.now()) && (_isToday(day) || _hasEntry(day));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.loadEntries('mood');
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _add([JournalEntry? entry]) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _MoodFormScreen(entry: entry)),
    );
    if (added == true) _load();
  }

  Future<void> _open(JournalEntry entry) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _MoodDetailScreen(entry: entry)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'reflections',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _MoodReflectionsScreen(entries: _entries),
              ),
            ),
            child: const Icon(Icons.psychology_alt),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _add(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TableCalendar<JournalEntry>(
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.twoWeeks,
            availableCalendarFormats: const {
              CalendarFormat.twoWeeks: 'Two weeks',
            },
            firstDay: _entries
                .map((e) => e.createdAt.toLocal())
                .fold(DateTime.now(), (a, b) => b.isBefore(a) ? b : a),
            lastDay: DateTime.now(),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => _sameDay(day, _selectedDay),
            enabledDayPredicate: _isEnabled,
            onDaySelected: (selected, focused) =>
                setState(() => _selectedDay = selected),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              disabledTextStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final dayEntries = _entries
                    .where(
                      (e) => _sameDay(e.createdAt.toLocal(), _selectedDay),
                    )
                    .toList();
                if (dayEntries.isEmpty) {
                  return Center(
                    child: Text(
                      S.t('empty_entries'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = dayEntries[index];
                    return _MoodPreviewCard(
                      entry: entry,
                      onTap: () => _open(entry),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodFormScreen extends StatefulWidget {
  const _MoodFormScreen({this.entry});

  final JournalEntry? entry;

  @override
  State<_MoodFormScreen> createState() => _MoodFormScreenState();
}

class _MoodFormScreenState extends State<_MoodFormScreen> {
  final _descriptionController = TextEditingController();
  final _anchorController = TextEditingController();
  final _reflectionController = TextEditingController();
  final _moods = <String>{};
  String _state = '';
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _moods.addAll(
        (entry.fields['mood']?.toString() ?? '')
            .split(', ')
            .where((m) => m.isNotEmpty),
      );
      _state = entry.fields['state']?.toString() ?? '';
      _descriptionController.text =
          entry.fields['description']?.toString() ?? '';
      _anchorController.text = entry.fields['anchor']?.toString() ?? '';
      _reflectionController.text =
          entry.fields['reflection']?.toString() ?? '';
      final photo = entry.fields['photo']?.toString() ?? '';
      if (photo.isNotEmpty) _photoPath = photo;
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _anchorController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<String?> _persistPhoto() async {
    var path = _photoPath;
    if (path == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    if (path.startsWith(dir.path)) return path;
    final photosDir = Directory('${dir.path}/mood_photos');
    await photosDir.create(recursive: true);
    final ext = path.split('.').last;
    final dest = '${photosDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(path).copy(dest);
    return dest;
  }

  Future<void> _save() async {
    final photoPath = await _persistPhoto();
    final oldPhoto = widget.entry?.fields['photo']?.toString();
    if (oldPhoto != null && oldPhoto.isNotEmpty && oldPhoto != photoPath) {
      final oldFile = File(oldPhoto);
      if (await oldFile.exists()) await oldFile.delete();
    }
    final entry = JournalEntry(
      id: widget.entry?.id,
      practiceId: 'mood',
      toolId: 'mood',
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      fields: {
        'mood': _moods.join(', '),
        'state': _state,
        'description': _descriptionController.text.trim(),
        'anchor': _anchorController.text.trim(),
        'reflection': _reflectionController.text.trim(),
        'photo': photoPath ?? '',
      },
    );
    if (widget.entry == null) {
      await JournalService.saveEntry(entry);
    } else {
      await JournalService.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _slide({required String label, required Widget child}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? S.t('mood') : S.t('edit')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(S.t('save')),
      ),
      body: PageView(
        children: [
          _slide(
            label: S.t('mood_state'),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final state in S.t('mood_states').split(','))
                  ChoiceChip(
                    label: Text(state),
                    selected: _state == state,
                    onSelected: (_) =>
                        setState(() => _state = _state == state ? '' : state),
                  ),
              ],
            ),
          ),
          _slide(
            label: S.t('mood_icon'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in [
                  'emotions_positive',
                  'emotions_negative',
                ]) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emotion in S.t(group).split(','))
                        ChoiceChip(
                          label: Text(emotion),
                          selected: _moods.contains(emotion),
                          onSelected: (selected) => setState(
                            () => selected
                                ? _moods.add(emotion)
                                : _moods.remove(emotion),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          _slide(
            label: S.t('mood_anchor'),
            child: TextField(
              controller: _anchorController,
              minLines: 5,
              maxLines: null,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: S.t('mood_anchor'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _slide(
            label: S.t('mood_description'),
            child: TextField(
              controller: _descriptionController,
              minLines: 5,
              maxLines: null,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: S.t('mood_description'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _slide(
            label: S.t('mood_reflection'),
            child: TextField(
              controller: _reflectionController,
              minLines: 5,
              maxLines: null,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: S.t('mood_reflection'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _slide(
            label: S.t('add_photo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_photoPath != null) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photoPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: S.t('remove_photo'),
                        onPressed: () => setState(() => _photoPath = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo),
                  label: Text(
                    S.t(_photoPath == null ? 'add_photo' : 'change_photo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodDetailScreen extends StatelessWidget {
  const _MoodDetailScreen({required this.entry});

  final JournalEntry entry;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mood = entry.fields['mood']?.toString() ?? '';
    final state = entry.fields['state']?.toString() ?? '';
    final description = entry.fields['description']?.toString() ?? '';
    final anchor = entry.fields['anchor']?.toString() ?? '';
    final reflection = entry.fields['reflection']?.toString() ?? '';
    final photo = entry.fields['photo']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(state.isNotEmpty ? state : S.t('mood')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: S.t('edit'),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => _MoodFormScreen(entry: entry),
                ),
              );
              if (changed == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isNotEmpty)
              Text(
                state,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (mood.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._moodLines(context, mood, onSurface.withValues(alpha: 0.6)),
            ],
            if (anchor.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${S.t('mood_anchor')}: $anchor',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: onSurface),
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: onSurface),
              ),
            ],
            if (reflection.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                reflection,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (photo.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(photo), fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _formatDate(entry.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodReflectionsScreen extends StatelessWidget {
  const _MoodReflectionsScreen({required this.entries});

  final List<JournalEntry> entries;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final reflections = entries
        .where((e) => (e.fields['reflection']?.toString() ?? '').isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(S.t('reflections'))),
      body: reflections.isEmpty
          ? Center(
              child: Text(
                S.t('empty_entries'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reflections.length,
              itemBuilder: (context, index) {
                final entry = reflections[index];
                final state = entry.fields['state']?.toString() ?? '';
                return Card(
                  color: const Color(0xFFF3E6EF),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.fields['reflection']!.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: onSurface,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (state.isNotEmpty) state,
                            _formatDate(entry.createdAt),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

List<Widget> _moodLines(
  BuildContext context,
  String mood,
  Color color,
) {
  final selected = mood.split(', ').where((m) => m.isNotEmpty).toSet();
  if (selected.isEmpty) return const [];
  final negative = S.t('emotions_negative').split(',').where(selected.contains);
  final positive = S.t('emotions_positive').split(',').where(selected.contains);
  final style = Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: color);
  return [
    if (negative.isNotEmpty) Text(negative.join(', '), style: style),
    if (positive.isNotEmpty) Text(positive.join(', '), style: style),
  ];
}

class _MoodPreviewCard extends StatelessWidget {
  const _MoodPreviewCard({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mood = entry.fields['mood']?.toString() ?? '';
    final state = entry.fields['state']?.toString() ?? '';
    final anchor = entry.fields['anchor']?.toString() ?? '';
    final photo = entry.fields['photo']?.toString() ?? '';
    return Card(
      color: const Color(0xFFF3E6EF),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isNotEmpty)
                Text(
                  state,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (mood.isNotEmpty) ...[
                const SizedBox(height: 4),
                ..._moodLines(
                  context,
                  mood,
                  onSurface.withValues(alpha: 0.6),
                ),
              ],
              if (anchor.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  anchor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onSurface),
                ),
              ],
              if (photo.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
