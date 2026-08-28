import 'package:flutter/material.dart';

import '../../theme/jagx_theme.dart';

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

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _out =
          'Local Code Lab notes (v1.1.2)\n'
          'Full sandboxed runs go through the JagX backend.\n'
          'Length: ${_code.text.length} chars\n'
          'Lines: ${_code.text.split('\n').length}\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Code Lab',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: JagxColors.fg)),
        const SizedBox(height: 6),
        const Text('Review code from Chat.',
            style: TextStyle(color: JagxColors.muted, height: 1.4)),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          maxLines: 14,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: JagxColors.fg),
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
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _run,
            style: FilledButton.styleFrom(backgroundColor: JagxColors.fg, foregroundColor: JagxColors.bg),
            child: const Text('Analyze'),
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
          child: Text(_out,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: JagxColors.fg, height: 1.45)),
        ),
      ],
    );
  }
}
