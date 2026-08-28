import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../books/book_studio_screen.dart';
import '../chat/chat_screen.dart';
import '../code/code_lab_screen.dart';
import '../images/image_studio_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Grade _grade = grades.first;
  bool _web = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final pages = [
      ChatScreen(grade: _grade, webEnabled: _web),
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
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'JagX ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: JagxColors.fg)),
              const TextSpan(text: 'AI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: JagxColors.accent)),
            ])),
            Text('v${AppConfig.version} · ${_grade.label}',
                style: const TextStyle(fontSize: 10, letterSpacing: 1.6, color: JagxColors.subtle, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          if (_tab == 0) ...[
            IconButton(
              tooltip: _web ? 'Web on' : 'Web off',
              onPressed: () => setState(() => _web = !_web),
              icon: Icon(Icons.public, color: _web ? JagxColors.accent : JagxColors.subtle),
            ),
            PopupMenuButton<String>(
              color: JagxColors.surface,
              onSelected: (id) => setState(() => _grade = gradeById(id)),
              itemBuilder: (context) => [
                for (final g in grades)
                  PopupMenuItem(value: g.id, child: Text('${g.label} — ${g.blurb}', style: const TextStyle(color: JagxColors.fg, fontSize: 13))),
              ],
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.tune, color: JagxColors.muted)),
            ),
          ],
          IconButton(
            onPressed: () async {
              if (auth.currentUser == null) {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else {
                await auth.signOut();
              }
              setState(() {});
            },
            icon: Icon(auth.currentUser == null ? Icons.person_outline : Icons.logout, color: JagxColors.muted),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: JagxColors.surface,
        indicatorColor: JagxColors.elevated,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
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
