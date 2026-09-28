import 'package:flutter/material.dart';
import '../models/unfold_models.dart';

class ReflectionDetailScreen extends StatelessWidget {
  final UnfoldEntry entry;

  const ReflectionDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fields = entry.fields;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          entry.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      ),
      body: fields.isEmpty
          ? _EmptyPage(entry: entry, onSurface: onSurface)
          : PageView.builder(
              itemCount: fields.length,
              itemBuilder: (context, index) =>
                  _FieldSlide(field: fields[index], onSurface: onSurface),
            ),
    );
  }
}

class _FieldSlide extends StatelessWidget {
  final UnfoldField field;
  final Color onSurface;

  const _FieldSlide({required this.field, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final paragraphs = _parseParagraphs(field.value, field.spans);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Card(
              color: const Color(0xFFF0E6D9),
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
                        field.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...paragraphs.map(
                        (p) =>
                            _ParagraphTile(paragraph: p, onSurface: onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParagraphTile extends StatelessWidget {
  final _Paragraph paragraph;
  final Color onSurface;

  const _ParagraphTile({required this.paragraph, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    if (paragraph.title == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text.rich(
          paragraph.body,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: onSurface),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: onSurface,
        collapsedIconColor: onSurface,
        title: Text(
          paragraph.title!,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text.rich(
              paragraph.body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraph {
  final String? title;
  final InlineSpan body;

  const _Paragraph(this.title, this.body);
}

List<_Paragraph> _parseParagraphs(String value, List<UnfoldSpan> spans) {
  const delimiter = '———';
  final parts = value.split(delimiter);
  if (parts.length == 1) {
    return [_Paragraph(null, _spanForRange(spans, 0, value.length, value))];
  }

  final result = <_Paragraph>[];
  var offset = 0;
  final preambleEnd = offset + parts[0].length;
  final preamble = value.substring(0, preambleEnd).trim();
  if (preamble.isNotEmpty) {
    result.add(_Paragraph(null, _spanForRange(spans, 0, preambleEnd, value)));
  }
  offset = preambleEnd + delimiter.length;

  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    final firstNewline = part.indexOf('\n');
    final headingEndInPart = firstNewline == -1 ? part.length : firstNewline;
    final bodyStartInPart = firstNewline == -1 ? part.length : firstNewline + 1;

    final headingStartOffset = offset;
    final headingEndOffset = offset + headingEndInPart;
    final bodyStartOffset = offset + bodyStartInPart;
    final bodyEndOffset = offset + part.length;

    final headingText = value
        .substring(headingStartOffset, headingEndOffset)
        .trim();
    final bodySpan = _spanForRange(
      spans,
      bodyStartOffset,
      bodyEndOffset,
      value,
    );
    result.add(_Paragraph(headingText.isEmpty ? null : headingText, bodySpan));
    offset += part.length + delimiter.length;
  }
  return result;
}

InlineSpan _spanForRange(
  List<UnfoldSpan> spans,
  int start,
  int end,
  String value,
) {
  if (start >= end) return const TextSpan(text: '');
  final s = value.indexOf(RegExp(r'\S'), start);
  if (s == -1 || s >= end) return const TextSpan(text: '');
  final e = value.lastIndexOf(RegExp(r'\S'), end - 1) + 1;
  if (spans.isEmpty) {
    return TextSpan(text: value.substring(s, e));
  }
  return TextSpan(children: _sliceSpans(spans, s, e));
}

List<InlineSpan> _sliceSpans(List<UnfoldSpan> spans, int start, int end) {
  final children = <InlineSpan>[];
  var offset = 0;
  for (final span in spans) {
    final length = span.text.length;
    final spanStart = offset;
    final spanEnd = offset + length;
    offset += length;
    if (spanEnd <= start || spanStart >= end) continue;
    final takeStart = start.clamp(spanStart, spanEnd) - spanStart;
    final takeEnd = end.clamp(spanStart, spanEnd) - spanStart;
    children.add(
      UnfoldSpan(
        text: span.text.substring(takeStart, takeEnd),
        bold: span.bold,
        italic: span.italic,
        underline: span.underline,
        strikethrough: span.strikethrough,
        code: span.code,
      ).toInlineSpan(),
    );
  }
  return children;
}

class _EmptyPage extends StatelessWidget {
  final UnfoldEntry entry;
  final Color onSurface;

  const _EmptyPage({required this.entry, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          entry.content.isEmpty ? 'Нет данных' : entry.content,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
