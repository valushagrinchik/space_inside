import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database.dart';
import '../core/l10n.dart';
import '../core/notion_service.dart';
import 'unfold/models/unfold_models.dart';

class NoteBook {
  final UnfoldEntry entry;
  final List<UnfoldEntry> quotes;

  const NoteBook({required this.entry, this.quotes = const []});

  Map<String, dynamic> toJson() => {
    'entry': entry.toJson(),
    'quotes': quotes.map((q) => q.toJson()).toList(),
  };

  factory NoteBook.fromJson(Map<String, dynamic> json) {
    final quotesJson = (json['quotes'] as List?)
        ?.cast<Map<String, dynamic>>();
    return NoteBook(
      entry: UnfoldEntry.fromJson(json['entry'] as Map<String, dynamic>),
      quotes: quotesJson?.map(UnfoldEntry.fromJson).toList() ?? [],
    );
  }
}

class NotesService {
  static final String _databaseId =
      dotenv.env['LEARNING_NOTES_DATABASE_ID'] ?? '';
  static const _cacheKey = 'learning_notes';

  static String _normalizeId(String id) => id.replaceAll('-', '');

  /// Finds the self-referencing relation property used for quotes -> book.
  static Future<String?> _relationProperty() async {
    final schema = await NotionService.getDatabase(_databaseId);
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    String? fallback;
    for (final entry in properties.entries) {
      final prop = entry.value;
      if (prop['type'] != 'relation') continue;
      final dbId = _normalizeId(
        (prop['relation'] as Map<String, dynamic>)['database_id']
                as String? ??
            '',
      );
      if (dbId != _normalizeId(_databaseId)) continue;
      if (entry.key.toLowerCase() == 'book') return entry.key;
      fallback ??= entry.key;
    }
    return fallback;
  }

  static Future<List<NoteBook>> loadRemote() async {
    final relationName = await _relationProperty();
    final pages = await NotionService.queryDatabase(_databaseId);

    final quotesByBook = <String, List<UnfoldEntry>>{};
    final books = <NoteBook>[];

    for (final page in pages) {
      final properties = page['properties'] as Map<String, dynamic>;
      final relations = relationName == null
          ? const <Map<String, dynamic>>[]
          : (properties[relationName]?['relation'] as List? ?? [])
                .cast<Map<String, dynamic>>();

      if (relations.isEmpty) {
        books.add(NoteBook(entry: _parsePage(page)));
      } else {
        quotesByBook
            .putIfAbsent(relations.first['id'] as String, () => [])
            .add(_parsePage(page));
      }
    }

    return [
      for (final book in books)
        NoteBook(
          entry: book.entry,
          quotes: quotesByBook[book.entry.id] ?? [],
        ),
    ];
  }

  static Future<List<NoteBook>?> loadLocal() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'notion_cache',
      where: 'key = ?',
      whereArgs: [_cacheKey],
    );
    if (rows.isEmpty) return null;
    final list = jsonDecode(rows.first['data'] as String) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(NoteBook.fromJson)
        .toList();
  }

  static Future<void> saveLocal(List<NoteBook> books) async {
    final db = await AppDatabase.instance;
    await db.insert('notion_cache', {
      'key': _cacheKey,
      'data': jsonEncode(books.map((b) => b.toJson()).toList()),
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String> createQuote({
    required String bookId,
    required String relationName,
    required String text,
    String author = '',
    List<String> tags = const [],
  }) {
    return NotionService.createPage(
      databaseId: _databaseId,
      properties: {
        'Name': {
          'title': [
            {
              'text': {'content': text},
            },
          ],
        },
        'Author': {
          'rich_text': [
            {
              'text': {'content': author},
            },
          ],
        },
        'Note': {
          'rich_text': [
            {
              'text': {'content': text},
            },
          ],
        },
        'Tags': {
          'multi_select': tags.map((t) => {'name': t}).toList(),
        },
        relationName: {
          'relation': [
            {'id': bookId},
          ],
        },
      },
    );
  }

  static Future<String?> relationPropertyName() => _relationProperty();

  static UnfoldEntry _parsePage(Map<String, dynamic> page) {
    final properties = page['properties'] as Map<String, dynamic>;
    final fields = <UnfoldField>[];
    for (final entry in properties.entries) {
      final prop = entry.value;
      final type = prop['type'] as String?;
      if (type == 'title' || type == 'relation') continue;
      final value = _propertyValue(prop);
      if (value == null || value.isEmpty) continue;
      fields.add(
        UnfoldField(
          label: entry.key,
          value: value,
          spans: type == 'rich_text' ? _richTextSpans(prop) : const [],
        ),
      );
    }
    return UnfoldEntry(
      id: page['id'] as String,
      name: _title(properties),
      content: _richText(properties['Note']),
      fields: fields,
    );
  }

  static String _title(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop['type'] == 'title') {
        final list = (prop['title'] as List).cast<Map<String, dynamic>>();
        final text = list
            .map((t) => t['plain_text'] as String? ?? '')
            .join()
            .trim();
        return text.isEmpty ? 'Untitled' : text;
      }
    }
    return 'Untitled';
  }

  static String _richText(dynamic prop) {
    if (prop == null || prop['type'] != 'rich_text') return '';
    final list = (prop['rich_text'] as List).cast<Map<String, dynamic>>();
    return list.map((t) => t['plain_text'] as String? ?? '').join().trim();
  }

  static List<UnfoldSpan> _richTextSpans(dynamic prop) {
    final list = (prop['rich_text'] as List).cast<Map<String, dynamic>>();
    return [
      for (final item in list)
        if ((item['plain_text'] as String? ?? '').isNotEmpty)
          UnfoldSpan(
            text: item['plain_text'] as String,
            bold: item['annotations']?['bold'] == true,
            italic: item['annotations']?['italic'] == true,
            underline: item['annotations']?['underline'] == true,
            strikethrough: item['annotations']?['strikethrough'] == true,
            code: item['annotations']?['code'] == true,
          ),
    ];
  }

  static String? _propertyValue(dynamic prop) {
    switch (prop['type'] as String?) {
      case 'rich_text':
        final text = _richText(prop);
        return text.isEmpty ? null : text;
      case 'multi_select':
        final options = (prop['multi_select'] as List)
            .cast<Map<String, dynamic>>();
        final text = options.map((o) => o['name'] as String).join(', ');
        return text.isEmpty ? null : text;
      case 'select':
        return prop['select']?['name'] as String?;
      case 'date':
        return prop['date']?['start'] as String?;
      default:
        return null;
    }
  }
}

String _quoteField(UnfoldEntry quote, String label) {
  for (final field in quote.fields) {
    if (field.label.toLowerCase() == label) return field.value;
  }
  return '';
}

class NotesTool extends StatefulWidget {
  const NotesTool({super.key});

  @override
  State<NotesTool> createState() => _NotesToolState();
}

class _NotesToolState extends State<NotesTool> {
  late Future<List<NoteBook>> _future;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _future = _loadLocal();
  }

  Future<List<NoteBook>> _loadLocal() async {
    return await NotesService.loadLocal() ?? [];
  }

  Future<List<NoteBook>> _sync() async {
    final books = await NotesService.loadRemote();
    await NotesService.saveLocal(books);
    return books;
  }

  void _onSync() {
    setState(() {
      _future = _sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_quote',
            onPressed: () async {
              final books = await _future;
              if (!context.mounted || books.isEmpty) return;
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddQuoteScreen(books: books),
                ),
              );
              if (added == true) _onSync();
            },
            backgroundColor: const Color(0xFFE4DFEF),
            child: Icon(Icons.add, color: onSurface),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'sync',
            onPressed: _onSync,
            backgroundColor: const Color(0xFFE4DFEF),
            child: Icon(Icons.sync, color: onSurface),
          ),
        ],
      ),
      body: FutureBuilder<List<NoteBook>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  S.fmt('error', {'error': '${snapshot.error}'}),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  S.t('unfold_empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }
          List<String> quoteTags(UnfoldEntry quote) => _quoteField(
            quote,
            'tags',
          ).split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

          final allTags = <String>{
            for (final book in books)
              for (final quote in book.quotes) ...quoteTags(quote),
          }.toList();

          final filteredBooks = _selectedTags.isEmpty
              ? books
              : [
                  for (final book in books)
                    if (book.quotes.any(
                      (q) => quoteTags(q).any(_selectedTags.contains),
                    ))
                      NoteBook(
                        entry: book.entry,
                        quotes: book.quotes
                            .where(
                              (q) =>
                                  quoteTags(q).any(_selectedTags.contains),
                            )
                            .toList(),
                      ),
                ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (allTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: allTags
                        .map(
                          (t) => FilterChip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                            selected: _selectedTags.contains(t),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _selectedTags.add(t);
                              } else {
                                _selectedTags.remove(t);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              for (final book in filteredBooks)
                _BookCard(book: book, onChanged: _onSync),
            ],
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final NoteBook book;
  final VoidCallback onChanged;

  const _BookCard({required this.book, required this.onChanged});

  String _fieldValue(String label) {
    for (final field in book.entry.fields) {
      if (field.label.toLowerCase() == label) return field.value;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final author = _fieldValue('author');
    return Card(
      color: const Color(0xFFE4DFEF),
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(book: book),
            ),
          );
          if (added == true) onChanged();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.entry.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (author.isNotEmpty)
                Text(
                  author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              if (book.quotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  S.fmt('quotes_count', {'count': '${book.quotes.length}'}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
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

class NoteDetailScreen extends StatefulWidget {
  final NoteBook book;

  const NoteDetailScreen({super.key, required this.book});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  String _bookAuthor() {
    for (final field in widget.book.entry.fields) {
      if (field.label.toLowerCase() == 'author') return field.value;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final quotes = widget.book.quotes;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.entry.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: onSurface),
            ),
            if (_bookAuthor().isNotEmpty)
              Text(
                _bookAuthor(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
      body: PageView.builder(
        itemCount: quotes.length + 1,
        itemBuilder: (context, index) {
          if (index == quotes.length) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: _QuoteForm(book: widget.book),
            );
          }
          return _QuoteSlide(quote: quotes[index], onSurface: onSurface);
        },
      ),
    );
  }
}

class AddQuoteScreen extends StatefulWidget {
  final List<NoteBook> books;

  const AddQuoteScreen({super.key, required this.books});

  @override
  State<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends State<AddQuoteScreen> {
  late NoteBook _book = widget.books.first;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          S.t('add_quote'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _book.entry.id,
              decoration: InputDecoration(
                labelText: S.t('book_title'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final book in widget.books)
                  DropdownMenuItem(
                    value: book.entry.id,
                    child: Text(
                      book.entry.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  _book = widget.books.firstWhere((b) => b.entry.id == id);
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _QuoteForm(key: ValueKey(_book.entry.id), book: _book)),
          ],
        ),
      ),
    );
  }
}

class _QuoteForm extends StatefulWidget {
  final NoteBook book;

  const _QuoteForm({super.key, required this.book});

  @override
  State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  final _textController = TextEditingController();
  late final _tagsController = TextEditingController(text: _bookField('tags'));
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _bookField(String label) {
    for (final field in widget.book.entry.fields) {
      if (field.label.toLowerCase() == label) return field.value;
    }
    return '';
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final relationName = await NotesService.relationPropertyName();
      if (relationName == null) {
        throw Exception('No relation property found in the database');
      }
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await NotesService.createQuote(
        bookId: widget.book.entry.id,
        relationName: relationName,
        text: text,
        author: _bookField('author'),
        tags: tags,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.fmt('error', {'error': '$e'}))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: const Color(0xFFE4DFEF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.t('add_quote'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                minLines: 5,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: S.t('quote_text'),
                  hintStyle: TextStyle(
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: S.t('tags_hint'),
                labelStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(S.t('save')),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _QuoteSlide extends StatelessWidget {
  final UnfoldEntry quote;
  final Color onSurface;

  const _QuoteSlide({required this.quote, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: const Color(0xFFE4DFEF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (final field in quote.fields)
                  if (field.label.toLowerCase() == 'note' &&
                      field.value.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text.rich(
                      field.spans.isEmpty
                          ? TextSpan(text: field.value)
                          : field.formatted,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: onSurface),
                    ),
                  ],
                for (final field in quote.fields)
                  if (field.label.toLowerCase() == 'tags') ...[
                    const SizedBox(height: 16),
                    Text(
                      field.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      field.value,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: onSurface),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
