import 'package:flutter/material.dart';
import '../../core/config.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../chat/chat_screen.dart';
import '../developer/developer_keys_screen.dart';
import '../plugins/plugin_center_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Grade _grade = grades.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JagX AI',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: JagxColors.fg),
            ),
            Text(
              'v${AppConfig.version}  •  AI workspace',
              style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: JagxColors.subtle, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Plugins',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PluginCenterScreen()),
            ),
            icon: const Icon(Icons.extension_outlined, color: JagxColors.muted),
          ),
          PopupMenuButton<String>(
            color: JagxColors.surface,
            onSelected: (value) async {
              if (value == 'developer') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperKeysScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'developer', child: Text('Developer API')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.more_horiz, color: JagxColors.muted),
            ),
          ),
        ],
      ),
      body: ChatScreen(
        grade: _grade,
        webEnabled: true,
        onGradeChanged: (grade) => setState(() => _grade = grade),
        onWebChanged: (_) {},
        showWebToggle: false,
      ),
    );
  }
}
