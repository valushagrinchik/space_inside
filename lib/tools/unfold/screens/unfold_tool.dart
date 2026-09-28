import 'package:flutter/material.dart';
import '../services/unfold_local_service.dart';
import '../services/unfold_service.dart';
import '../models/unfold_models.dart';
import 'reflection_detail_screen.dart';

class UnfoldTool extends StatefulWidget {
  const UnfoldTool({super.key});

  @override
  State<UnfoldTool> createState() => _UnfoldToolState();
}

class _UnfoldToolState extends State<UnfoldTool> {
  late Future<List<UnfoldPeriod>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadLocal();
  }

  Future<List<UnfoldPeriod>> _loadLocal() async {
    final periods = await UnfoldLocalService.load();
    return periods ?? [];
  }

  Future<List<UnfoldPeriod>> _sync() async {
    final periods = await UnfoldService.loadPeriods();
    await UnfoldLocalService.save(periods);
    return periods;
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onSync,
        backgroundColor: const Color(0xFFF0E6D9),
        child: Icon(Icons.sync, color: onSurface),
      ),
      body: FutureBuilder<List<UnfoldPeriod>>(
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
                  'Ошибка: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }

          final periods = snapshot.data!;
          if (periods.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Нет сохранённых данных.\nНажмите синхронизацию, чтобы загрузить данные из Notion.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }

          return PageView.builder(
            itemCount: periods.length,
            itemBuilder: (context, index) =>
                _PeriodPage(period: periods[index], onSurface: onSurface),
          );
        },
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  final UnfoldPeriod period;
  final Color onSurface;

  const _PeriodHeader({required this.period, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final date = period.date;
    final dateStr = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dateStr.isNotEmpty ||
              period.context != null ||
              period.themes.isNotEmpty)
            const SizedBox(height: 4),
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          if (period.context != null)
            Text(
              period.context!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          if (period.themes.isNotEmpty)
            Text(
              period.themes.join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodPage extends StatelessWidget {
  final UnfoldPeriod period;
  final Color onSurface;

  const _PeriodPage({required this.period, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      _PeriodHeader(period: period, onSurface: onSurface),
    ];
    if (period.entries.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Нет рефлексий',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    } else {
      for (final entry in period.entries) {
        widgets.add(_ReflectionTile(entry: entry));
      }
    }

    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }
}

class _ReflectionTile extends StatelessWidget {
  final UnfoldEntry entry;

  const _ReflectionTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    var displayText = entry.content;
    for (final field in entry.fields) {
      if (field.label.toLowerCase() == 'feelings') {
        displayText = field.value;
        break;
      }
    }
    return Card(
      color: const Color(0xFFF0E6D9),
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReflectionDetailScreen(entry: entry),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (displayText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  displayText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
