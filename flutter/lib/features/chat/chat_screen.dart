import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import 'chat_models.dart';

class _Attachment {
  final String name;
  final String type;
  const _Attachment({required this.name, required this.type});
}

class ChatScreen extends StatefulWidget {
  final Grade grade;
  final bool webEnabled;
  final ValueChanged<Grade> onGradeChanged;
  final ValueChanged<bool> onWebChanged;
  const ChatScreen({
    super.key,
    required this.grade,
    required this.webEnabled,
    required this.onGradeChanged,
    required this.onWebChanged,
  });
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = const Uuid();
  final List<ChatMessage> _messages = [];
  final List<_Attachment> _attachments = [];
  bool _busy = false;
  String _live = 'Thinking';
  int _liveIdx = 0;
  final _liveSteps = const ['Parsing intent','Searching the live web','Reading sources','Thinking','Writing'];

  @override void dispose(){_input.dispose();_scroll.dispose();super.dispose();}

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || !mounted) return;
    setState(() {
      for (final file in result.files) {
        if (_attachments.length >= 8) break;
        _attachments.add(_Attachment(name: file.name, type: _mime(file.extension ?? '')));
      }
    });
  }

  String _mime(String ext) {
    const map = {'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif','pdf':'application/pdf','txt':'text/plain','md':'text/markdown','json':'application/json','dart':'text/plain','kt':'text/plain','java':'text/plain','ts':'text/plain','tsx':'text/plain','js':'text/plain','py':'text/plain','go':'text/plain','rs':'text/plain'};
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if ((text.isEmpty && _attachments.isEmpty) || _busy) return;
    final attached = List<_Attachment>.from(_attachments);
    final prompt = (text.isEmpty ? 'Please inspect the attached files.' : text) +
        (attached.isEmpty ? '' : '\n\nATTACHMENTS:\n' + attached.map((a) => '- ' + a.name + ' (' + a.type + ')').join('\n'));
    setState(() {
      _busy = true; _liveIdx = 0; _live = _liveSteps[0]; _input.clear(); _attachments.clear();
      _messages.add(ChatMessage(id: _uuid.v4(), role: 'user', content: prompt));
      _messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: '', pending: true));
    });
    final pendingId = _messages.last.id;
    final ticker = Stream.periodic(const Duration(milliseconds: 900)).listen((_) {
      if (!mounted || !_busy) return;
      setState(() { _liveIdx = (_liveIdx + 1) % _liveSteps.length; _live = _liveSteps[_liveIdx]; });
    });
    final history = _messages.where((m) => !m.pending && m.content.isNotEmpty).take(_messages.length - 2).map((m) => ChatTurn(role: m.role, content: m.content)).toList();
    final result = await AiService(onStep: (step) { if (mounted) setState(() => _live = step.label); }).chat(message: prompt, history: history, grade: widget.grade, web: widget.webEnabled);
    await ticker.cancel();
    if (!mounted) return;
    setState(() {
      _busy = false;
      final i = _messages.indexWhere((m) => m.id == pendingId);
      if (i >= 0) {
        _messages[i] = ChatMessage(id: pendingId, role: 'assistant', content: result.ok ? result.text : (result.error ?? 'Failed'), steps: result.steps, sources: result.sources, durationMs: result.durationMs, model: result.model);
      }
    });
  }

  void _showModes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JagxColors.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            const Text(
              'JagX modes',
              style: TextStyle(
                color: JagxColors.fg,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final mode in grades)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  mode.label,
                  style: const TextStyle(
                    color: JagxColors.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  mode.blurb,
                  style: const TextStyle(color: JagxColors.muted),
                ),
                trailing: mode.id == widget.grade.id
                    ? const Icon(Icons.check, color: JagxColors.accent)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (mode.id != widget.grade.id) {
                    widget.onGradeChanged(mode);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Column(children: [Expanded(child: _messages.isEmpty ? _empty() : _list()), _composer()]);
  }

  Widget _empty() {
    const hints = ['Design a fault-tolerant job queue','Write a TypeScript rate limiter','What shipped in AI this week?'];
    return ListView(padding: const EdgeInsets.fromLTRB(20,48,20,20), children: [
      const Text('Ask JagX anything', textAlign: TextAlign.center, style: TextStyle(fontSize:28,fontWeight:FontWeight.w600,color:JagxColors.fg)),
      const SizedBox(height:10),
      const Text('Live web research • coding terminal • books • image studio', textAlign:TextAlign.center, style:TextStyle(color:JagxColors.muted)),
      const SizedBox(height:28),
      ...hints.map((hint) => Padding(
        padding: const EdgeInsets.only(bottom:8),
        child: Material(color:JagxColors.surface,borderRadius:BorderRadius.circular(16),child:InkWell(onTap:()=>_send(hint),child:Padding(padding:const EdgeInsets.all(14),child:Text(hint,style:const TextStyle(color:JagxColors.muted))))),
      )),
    ]);
  }

  Widget _list() {
    return ListView.builder(
      controller:_scroll,padding:const EdgeInsets.all(16),itemCount:_messages.length,
      itemBuilder:(context,index){
        final m=_messages[index];
        if(m.role=='user') return Align(alignment:Alignment.centerRight,child:Container(margin:const EdgeInsets.only(bottom:16,left:40),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:JagxColors.elevated,borderRadius:BorderRadius.circular(18)),child:Text(m.content,style:const TextStyle(color:JagxColors.fg))));
        if(m.pending) return Padding(padding:const EdgeInsets.only(bottom:20),child:Text(_live.toUpperCase(),style:const TextStyle(color:JagxColors.accent,fontSize:11,letterSpacing:1.6,fontFamily:'monospace')));
        return Padding(padding:const EdgeInsets.only(bottom:24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          ...m.steps.map((s)=>Text('· '+s.label,style:const TextStyle(color:JagxColors.subtle,fontSize:11,fontFamily:'monospace'))),
          MarkdownBody(data:m.content,styleSheet:MarkdownStyleSheet(p:const TextStyle(color:JagxColors.fg,height:1.55))),
        ]));
      },
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                ActionChip(
                  avatar: Icon(
                    widget.webEnabled ? Icons.public : Icons.public_off,
                    size: 17,
                    color: widget.webEnabled
                        ? JagxColors.accent
                        : JagxColors.muted,
                  ),
                  label: Text(widget.webEnabled ? 'Web' : 'Web off'),
                  onPressed: _busy
                      ? null
                      : () => widget.onWebChanged(!widget.webEnabled),
                  backgroundColor: JagxColors.surface,
                  labelStyle: const TextStyle(color: JagxColors.fg),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 17, color: JagxColors.fg),
                  label: Text(widget.grade.label),
                  onPressed: _busy ? null : _showModes,
                  backgroundColor: JagxColors.surface,
                  labelStyle: const TextStyle(color: JagxColors.fg),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            if (_attachments.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _attachments.length.toString() + ' attachment(s) ready',
                  style: const TextStyle(color: JagxColors.muted, fontSize: 12),
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Attach files, images, PDFs and code',
                  onPressed: _busy ? null : _pickFiles,
                  icon: const Icon(Icons.add_circle_outline, size: 28, color: JagxColors.fg),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Message JagX AI',
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy ? null : () => _send(),
                  style: IconButton.styleFrom(
                    backgroundColor: JagxColors.fg,
                    foregroundColor: JagxColors.bg,
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
