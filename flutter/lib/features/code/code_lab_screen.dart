import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';

class CodeLabScreen extends StatefulWidget {
  const CodeLabScreen({super.key});

  @override
  State<CodeLabScreen> createState() => _CodeLabScreenState();
}

class _CodeLabScreenState extends State<CodeLabScreen> {
  final _code = TextEditingController(
    text: '''// JagX Code Lab
final a = [0, 1];
while (a.length < 12) {
  a.add(a[a.length - 1] + a[a.length - 2]);
}
print(a.join(', '));
''',
  );
  String _out = 'Output appears here.';
  bool _busy = false;
  String _status = '';

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _status = 'Reading code…';
      _out = '';
    });
    try {
      final text = await AiService(
        onStep: (s) {
          if (mounted) setState(() => _status = s.label);
        },
      ).analyzeCode(_code.text);
      setState(() => _out = text);
    } catch (e) {
      setState(() => _out = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _improve() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _status = 'Rewriting…';
    });
    try {
      final r = await AiService().chat(
        message:
            'Rewrite this code cleaner and safer. Return only the improved code in a single fenced block:\n\n```\n${_code.text}\n```',
        history: const [],
        grade: gradeById('engineer'),
        web: false,
      );
      if (r.ok) {
        final match =
            RegExp(r'```(?:\w+)?\n([\s\S]*?)```').firstMatch(r.text);
        setState(() {
          _out = r.text;
          if (match != null) _code.text = match.group(1)!.trim();
        });
      } else {
        setState(() => _out = r.error ?? 'Failed');
      }
    } catch (e) {
      setState(() => _out = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Code Lab',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: JagxColors.fg,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste code. JagX analyzes, explains, and can rewrite it.',
          style: TextStyle(color: JagxColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          maxLines: 14,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: JagxColors.fg,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: JagxColors.elevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: JagxColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: _busy ? null : _analyze,
              style: FilledButton.styleFrom(
                backgroundColor: JagxColors.fg,
                foregroundColor: JagxColors.bg,
              ),
              child: Text(_busy ? 'Working…' : 'Analyze'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _busy ? null : _improve,
              child: const Text('Improve'),
            ),
          ],
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
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JagxColors.elevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JagxColors.border),
          ),
          child: _out.contains('#') || _out.contains('```')
              ? MarkdownBody(
                  data: _out,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: JagxColors.fg,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    code: const TextStyle(
                      fontFamily: 'monospace',
                      color: JagxColors.fg,
                    ),
                  ),
                )
              : Text(
                  _out,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: JagxColors.fg,
                    height: 1.45,
                  ),
                ),
        ),
      ],
    );
  }
}
