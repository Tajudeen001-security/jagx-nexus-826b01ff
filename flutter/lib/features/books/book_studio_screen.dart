import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/ai_service.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';

class BookStudioScreen extends StatefulWidget {
  const BookStudioScreen({super.key});
  @override
  State<BookStudioScreen> createState() => _BookStudioScreenState();
}

class _BookStudioScreenState extends State<BookStudioScreen> {
  final _topic = TextEditingController();
  int _chapters = 6;
  bool _busy = false;
  String? _md;
  String? _error;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true || !mounted) return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final md = await AiService().generateBook(topic: _topic.text.trim(), chapters: _chapters);
      setState(() => _md = md);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Book Studio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: JagxColors.fg)),
        const SizedBox(height: 6),
        const Text('Generate a Markdown book, then share it.', style: TextStyle(color: JagxColors.muted)),
        const SizedBox(height: 16),
        TextField(controller: _topic, decoration: const InputDecoration(hintText: 'Topic')),
        Row(children: [
          const Text('Chapters', style: TextStyle(color: JagxColors.muted)),
          Expanded(child: Slider(value: _chapters.toDouble(), min: 3, max: 12, divisions: 9,
            activeColor: JagxColors.accent, onChanged: (v) => setState(() => _chapters = v.round()))),
          Text('$_chapters', style: const TextStyle(color: JagxColors.fg)),
        ]),
        FilledButton(
          onPressed: _busy || _topic.text.trim().isEmpty ? null : _go,
          style: FilledButton.styleFrom(backgroundColor: JagxColors.fg, foregroundColor: JagxColors.bg, minimumSize: const Size.fromHeight(48)),
          child: Text(_busy ? 'Writing…' : 'Write book'),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: JagxColors.danger)),
        if (_md != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Share.share(_md!, subject: 'JagX AI Book'),
            child: const Text('Share / export Markdown'),
          ),
          const SizedBox(height: 16),
          MarkdownBody(data: _md!),
        ],
      ],
    );
  }
}
