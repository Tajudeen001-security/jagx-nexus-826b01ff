import 'package:flutter/material.dart';
import '../../core/fast_ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';

class NexusChatScreen extends StatefulWidget {
  final Grade grade;
  final ValueChanged<Grade> onGradeChanged;
  const NexusChatScreen({super.key, required this.grade, required this.onGradeChanged});
  @override State<NexusChatScreen> createState() => _NexusChatScreenState();
}

class _NexusChatScreenState extends State<NexusChatScreen> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[];
  bool busy = false;

  @override void dispose() { controller.dispose(); super.dispose(); }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || busy) return;
    final history = List<Map<String, String>>.from(messages);
    controller.clear();
    setState(() {
      messages.add({'role': 'user', 'content': text});
      busy = true;
    });
    try {
      final result = await FastAiService.complete(
        message: text,
        history: history,
        coding: _isCodingMode,
        onProgress: (status) {
          if (mounted) setState(() => _status = status);
        },
      );
      if (!mounted) return;
      setState(() {
        messages.add({'role': 'assistant', 'content': result.text, 'model': '${result.provider} • ${result.model}'});
        busy = false;
        _status = '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages.add({'role': 'assistant', 'content': 'I could not reach an AI provider. Check the configured API keys and try again.\n\n$error'});
        busy = false;
        _status = '';
      });
    }
  }

  String _status = '';
  bool get _isCodingMode => widget.grade.id == 'engineer' || widget.grade.id == 'operator' || widget.grade.id == 'coder-fast';

  void modes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JagxColors.surface,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('AI modes', style: TextStyle(color: JagxColors.fg, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...grades.map((g) => ListTile(
            title: Text(g.label, style: const TextStyle(color: JagxColors.fg)),
            subtitle: Text(g.blurb, style: const TextStyle(color: JagxColors.muted)),
            trailing: g.id == widget.grade.id ? const Icon(Icons.check, color: JagxColors.accent) : null,
            onTap: () { Navigator.pop(context); widget.onGradeChanged(g); },
          )),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: messages.isEmpty
            ? const SizedBox.expand()
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final user = message['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Align(
                      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 680),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: user ? JagxColors.elevated : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (!user && message['model'] != null) Text(message['model']!, style: const TextStyle(color: JagxColors.subtle, fontSize: 10)),
                          SelectableText(message['content'] ?? '', style: const TextStyle(color: JagxColors.fg, height: 1.5)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
      if (busy) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(_status.isEmpty ? 'Working…' : _status, style: const TextStyle(color: JagxColors.muted, fontSize: 12))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: JagxColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: JagxColors.elevated)),
        child: Row(children: [
          IconButton(onPressed: busy ? null : modes, icon: const Icon(Icons.tune, color: JagxColors.muted)),
          Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 7, decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none), onSubmitted: (_) => send())),
          IconButton.filled(onPressed: busy ? null : send, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward)),
        ]),
      ))),
    ]);
  }
}
