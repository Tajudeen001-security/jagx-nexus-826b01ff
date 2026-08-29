import 'package:flutter/material.dart';
import '../../core/config.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../books/book_studio_screen.dart';
import '../chat/chat_screen.dart';
import '../code/code_lab_screen.dart';
import '../developer/developer_keys_screen.dart';
import '../images/image_studio_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Grade _grade = grades.first;
  bool _web = true;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ChatScreen(
        grade: _grade,
        webEnabled: _web,
        onGradeChanged: (grade) => setState(() => _grade = grade),
        onWebChanged: (enabled) => setState(() => _web = enabled),
      ),
      const CodeLabScreen(),
      const BookStudioScreen(),
      const ImageStudioScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JagX AI',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: JagxColors.fg),
            ),
            Text(
              'v' + AppConfig.version,
              style: const TextStyle(fontSize: 10, letterSpacing: 1.6, color: JagxColors.subtle, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [

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
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: JagxColors.surface,
        indicatorColor: JagxColors.elevated,
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.terminal), selectedIcon: Icon(Icons.terminal), label: 'Code'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Books'),
          NavigationDestination(icon: Icon(Icons.image_outlined), selectedIcon: Icon(Icons.image), label: 'Images'),
        ],
      ),
    );
  }
}
