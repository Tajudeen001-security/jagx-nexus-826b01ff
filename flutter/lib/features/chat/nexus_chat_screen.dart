import 'package:flutter/material.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';

class NexusChatScreen extends StatefulWidget {
  final Grade grade;
  final ValueChanged<Grade> onGradeChanged;
  const NexusChatScreen({super.key, required this.grade, required this.onGradeChanged});

  @override
  State<NexusChatScreen> createState() => _NexusChatScreenState();
}

class _NexusChatScreenState extends State<NexusChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = <Map<String, String>>[];
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final String text = controller.text.trim();
    if (text.isEmpty || busy) return;
    setState(() {
      messages.add(<String, String>{'role': 'user', 'text': text});
      controller.clear();
      busy = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        busy = false;
        messages.add(<String, String>{'role': 'assistant', 'text': 'JagX AI is ready.'});
      });
    });
  }

  void modes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JagxColors.surface,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            const Text('AI modes', style: TextStyle(color: JagxColors.fg, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...grades.map((Grade g) => ListTile(
              title: Text(g.label, style: const TextStyle(color: JagxColors.fg)),
              subtitle: Text(g.blurb, style: const TextStyle(color: JagxColors.muted)),
              trailing: g.id == widget.grade.id ? const Icon(Icons.check, color: JagxColors.accent) : null,
              onTap: () {
                Navigator.pop(context);
                widget.onGradeChanged(g);
              },
            )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: messages.isEmpty
              ? const SizedBox.expand()
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, String> message = messages[index];
                    final bool user = message['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Align(
                        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 680),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: JagxColors.elevated,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: SelectableText(
                            message['text'] ?? '',
                            style: const TextStyle(color: JagxColors.fg, height: 1.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Working…', style: TextStyle(color: JagxColors.muted, fontSize: 12)),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: JagxColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: JagxColors.elevated),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(onPressed: modes, icon: const Icon(Icons.tune, color: JagxColors.muted)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 7,
                      decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  IconButton.filled(onPressed: send, icon: const Icon(Icons.arrow_upward)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
