import 'package:flutter/material.dart';
import '../core/tool_config.dart';
import '../core/tool_icon.dart';
import '../core/tool_registry.dart';
import '../core/settings_service.dart';
import 'settings_screen.dart';
import 'tool_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final tools = await ToolRegistry.load();
    final ids = tools.map((t) => t.id).toList();
    final visible = await SettingsService.loadVisibleTools(ids);
    final filtered = tools.where((t) => visible.contains(t.id)).toList();
    return _HomeData(all: tools, visible: filtered);
  }

  void _refresh() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        return Scaffold(
          appBar: null,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon/icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Space Inside',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontFamily: 'Cormorant Garamond',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            Text(
                              'your space to notice, grow and remember',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _openSettings(context, data.all),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: data.visible.length,
                    itemBuilder: (context, index) {
                      final tool = data.visible[index];
                      return _ToolCard(tool: tool);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.10,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'A little space\nfor what matters',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Cormorant Garamond',
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context, List<ToolConfig> tools) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => SettingsScreen(tools: tools)),
    ).then((_) {
      if (mounted) _refresh();
    });
  }
}

class _HomeData {
  final List<ToolConfig> all;
  final List<ToolConfig> visible;
  const _HomeData({required this.all, required this.visible});
}

class _ToolCard extends StatelessWidget {
  final ToolConfig tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(tool.color);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTool(context, tool),
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  resolveIcon(tool.icon),
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 12),
                Text(
                  tool.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (tool.description != null &&
                    tool.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth ,
                    ),
                    child: Text(
                      tool.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _openTool(BuildContext context, ToolConfig tool) {
    final builder = ToolRegistry.builder(tool.id);
    if (builder == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ToolScreen(config: tool, childBuilder: builder),
      ),
    );
  }
}
