import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'chat_models.dart';

class ChatScreen extends StatefulWidget {
  final Grade grade;
  final bool webEnabled;
  const ChatScreen({super.key, required this.grade, required this.webEnabled});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = const Uuid();
  final List<ChatMessage> _messages = [];
  bool _busy = false;
  String _live = 'Thinking';
  final _liveSteps = const ['Parsing intent', 'Searching the live web', 'Reading sources', 'Thinking', 'Writing'];
  int _liveIdx = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _liveIdx = 0;
      _live = _liveSteps[0];
      _input.clear();
      _messages.add(ChatMessage(id: _uuid.v4(), role: 'user', content: text));
      _messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: '', pending: true));
    });
    final pendingId = _messages.last.id;
    final ticker = Stream.periodic(const Duration(milliseconds: 900)).listen((_) {
      if (!mounted || !_busy) return;
      setState(() { _liveIdx = (_liveIdx + 1) % _liveSteps.length; _live = _liveSteps[_liveIdx]; });
    });
    final history = _messages.where((m) => !m.pending && m.content.isNotEmpty).take(_messages.length - 2)
        .map((m) => ChatTurn(role: m.role, content: m.content)).toList();
    final ai = AiService(onStep: (s) { if (mounted) setState(() => _live = s.label); });
    final result = await ai.chat(message: text, history: history, grade: widget.grade, web: widget.webEnabled);
    await ticker.cancel();
    if (!mounted) return;
    setState(() {
      _busy = false;
      final i = _messages.indexWhere((m) => m.id == pendingId);
      if (i >= 0) {
        _messages[i] = ChatMessage(
          id: pendingId, role: 'assistant',
          content: result.ok ? result.text : (result.error ?? 'Failed'),
          steps: result.steps, sources: result.sources,
          durationMs: result.durationMs, model: result.model,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _messages.isEmpty ? _empty() : _list()),
      _composer(),
    ]);
  }

  Widget _empty() {
    const hints = ['Design a fault-tolerant job queue in Postgres', 'Write a TypeScript rate limiter with tests', 'What shipped in AI this week?'];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 48, 20, 20), children: [
      const Text('Ask JagX anything', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: JagxColors.fg)),
      const SizedBox(height: 10),
      const Text('Thirteen modes, live web, code, books, images.\nBuilt by JagX & JRILICENSE.', textAlign: TextAlign.center, style: TextStyle(color: JagxColors.muted)),
      const SizedBox(height: 28),
      ...hints.map((h) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: JagxColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _send(h),
            child: Padding(padding: const EdgeInsets.all(14), child: Text(h, style: const TextStyle(color: JagxColors.muted)))),
        ),
      )),
    ]);
  }

  Widget _list() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        if (m.role == 'user') {
          return Align(alignment: Alignment.centerRight, child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: JagxColors.elevated, borderRadius: BorderRadius.circular(16)),
            child: Text(m.content, style: const TextStyle(color: JagxColors.fg)),
          ));
        }
        if (m.pending) {
          return Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(_live.toUpperCase(),
            style: const TextStyle(color: JagxColors.accent, fontSize: 11, letterSpacing: 1.6, fontFamily: 'monospace')));
        }
        return Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...m.steps.map((s) => Text('· ${s.label}', style: const TextStyle(color: JagxColors.subtle, fontSize: 11, fontFamily: 'monospace'))),
          MarkdownBody(data: m.content, styleSheet: MarkdownStyleSheet(p: const TextStyle(color: JagxColors.fg, height: 1.55))),
          if (m.durationMs != null) Text('${m.durationMs! < 1000 ? '${m.durationMs} ms' : '${(m.durationMs! / 1000).toStringAsFixed(1)} s'} · ${m.model ?? ''}'.toUpperCase(),
            style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: JagxColors.subtle, fontFamily: 'monospace')),
        ]));
      },
    );
  }

  Widget _composer() {
    return SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _input,
          style: const TextStyle(color: JagxColors.fg),
          decoration: const InputDecoration(hintText: 'Message JagX AI'),
          onSubmitted: (_) => _send(),
        )),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _busy ? null : () => _send(),
          style: IconButton.styleFrom(backgroundColor: JagxColors.fg, foregroundColor: JagxColors.bg),
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward),
        ),
      ]),
    ));
  }
}
