import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/jagx_theme.dart';

class PluginCenterScreen extends StatefulWidget {
  const PluginCenterScreen({super.key});
  @override State<PluginCenterScreen> createState() => _PluginCenterScreenState();
}

class _PluginCenterScreenState extends State<PluginCenterScreen> {
  final _plugins = const [
    ('GitHub', 'Repositories, issues, pull requests and code', Icons.code),
    ('Supabase', 'Database, auth, storage and edge functions', Icons.storage),
    ('Email', 'Draft, send and organize email through a connector', Icons.email_outlined),
    ('Webhooks / APIs', 'Connect almost any REST API or automation', Icons.link),
    ('Google Drive', 'Read and create documents and files', Icons.cloud_outlined),
  ];
  final Set<String> _connected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _connected.addAll(prefs.getStringList('jagx_plugins') ?? const []));
  }

  Future<void> _toggle(String name) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_connected.contains(name)) {
        _connected.remove(name);
      } else {
        _connected.add(name);
      }
    });
    await prefs.setStringList('jagx_plugins', _connected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Connect JagX to your tools',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: JagxColors.fg),
          ),
          const SizedBox(height: 8),
          const Text(
            'JagX uses connectors instead of putting third-party secrets directly in the app. '
            'A connected plugin becomes available to the AI as a tool.',
            style: TextStyle(color: JagxColors.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          ..._plugins.map((plugin) => Card(
            color: JagxColors.surface,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: JagxColors.elevated,
                child: Icon(plugin.$3, color: JagxColors.fg),
              ),
              title: Text(plugin.$1, style: const TextStyle(color: JagxColors.fg, fontWeight: FontWeight.w600)),
              subtitle: Text(plugin.$2, style: const TextStyle(color: JagxColors.muted)),
              trailing: OutlinedButton(
                onPressed: () => _toggle(plugin.$1),
                child: Text(_connected.contains(plugin.$1) ? 'Connected' : 'Connect'),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
