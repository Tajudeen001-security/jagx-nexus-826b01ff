import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
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
  String _status = '';

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Outlining chapters…';
    });
    try {
      final md = await AiService(
        onStep: (s) {
          if (mounted) setState(() => _status = s.label);
        },
      ).generateBook(topic: _topic.text.trim(), chapters: _chapters);
      setState(() {
        _md = md;
        _status = 'Book ready';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareMarkdown() async {
    if (_md == null) return;
    await Share.share(_md!, subject: 'JagX AI Book');
  }

  Future<void> _exportFile() async {
    if (_md == null) return;
    final dir = await getTemporaryDirectory();
    final name = 'jagx-book-${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${dir.path}/$name');
    await file.writeAsString(_md!);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'JagX AI Book',
      text: 'Generated with JagX AI 1.1.2',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Book Studio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: JagxColors.fg,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Generate a structured Markdown book, then share or export the file. '
          'Open the .md in any editor or print to PDF from your device.',
          style: TextStyle(color: JagxColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _topic,
          decoration: const InputDecoration(hintText: 'Topic'),
          onChanged: (_) => setState(() {}),
        ),
        Row(
          children: [
            const Text('Chapters', style: TextStyle(color: JagxColors.muted)),
            Expanded(
              child: Slider(
                value: _chapters.toDouble(),
                min: 3,
                max: 12,
                divisions: 9,
                activeColor: JagxColors.accent,
                onChanged: (v) => setState(() => _chapters = v.round()),
              ),
            ),
            Text('$_chapters', style: const TextStyle(color: JagxColors.fg)),
          ],
        ),
        FilledButton(
          onPressed: _busy || _topic.text.trim().isEmpty ? null : _go,
          style: FilledButton.styleFrom(
            backgroundColor: JagxColors.fg,
            foregroundColor: JagxColors.bg,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(_busy ? (_status.isEmpty ? 'Writing…' : _status) : 'Write book'),
        ),
        if (_busy)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _status.toUpperCase(),
              style: const TextStyle(
                color: JagxColors.accent,
                fontSize: 11,
                letterSpacing: 1.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: JagxColors.danger)),
          ),
        if (_md != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _shareMarkdown,
                  child: const Text('Share text'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _exportFile,
                  child: const Text('Export .md'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: _md!,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: JagxColors.fg, height: 1.5),
              h1: const TextStyle(
                color: JagxColors.fg,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              h2: const TextStyle(
                color: JagxColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
