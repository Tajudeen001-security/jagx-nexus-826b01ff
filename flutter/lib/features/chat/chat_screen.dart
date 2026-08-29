import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../plugins/plugin_center_screen.dart';
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
  final bool showWebToggle;
  const ChatScreen({
    super.key,
    required this.grade,
    required this.webEnabled,
    required this.onGradeChanged,
    required this.onWebChanged,
    this.showWebToggle = true,
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

  bool _looksLikeImage(String text) => RegExp(r'\b(generate|create|draw|make|design)\b[\s\S]*\b(image|picture|logo|poster|illustration|wallpaper)\b', caseSensitive: false).hasMatch(text);
  bool _looksLikePdf(String text) => RegExp(r'\b(create|make|generate|write|turn)\b[\s\S]*\b(pdf|ebook|e-book|story book|storybook|book|document)\b', caseSensitive: false).hasMatch(text);
  bool _looksLikeZip(String text) => RegExp(r'\b(create|make|generate|package|zip|bundle|build)\b[\s\S]*\b(zip|project|files|codebase|app|website)\b', caseSensitive: false).hasMatch(text);

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if ((text.isEmpty && _attachments.isEmpty) || _busy) return;
    final attached = List<_Attachment>.from(_attachments);
    final prompt = (text.isEmpty ? 'Please inspect the attached files.' : text) + (attached.isEmpty ? '' : '\n\nATTACHMENTS:\n' + attached.map((a) => '- ' + a.name + ' (' + a.type + ')').join('\n'));
    setState(() { _busy = true; _liveIdx = 0; _live = _liveSteps[0]; _input.clear(); _attachments.clear(); _messages.add(ChatMessage(id: _uuid.v4(), role: 'user', content: prompt)); _messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: '', pending: true)); });
    final pendingId = _messages.last.id;
    final ticker = Stream.periodic(const Duration(milliseconds: 700)).listen((_) { if (!mounted || !_busy) return; setState(() { _liveIdx = (_liveIdx + 1) % _liveSteps.length; _live = _liveSteps[_liveIdx]; }); });
    try {
      if (_looksLikeImage(text)) { final url = await AiService().generateImageUrl(text); await ticker.cancel(); if (!mounted) return; _finish(pendingId, 'Generated image for your request.', imageUrl: url, model: 'image'); return; }
      if (_looksLikePdf(text)) { final markdown = await AiService(onStep: (s) { if (mounted) setState(() => _live = s.label); }).generateBook(topic: text, chapters: 6); final path = await _writePdf(markdown); await ticker.cancel(); if (!mounted) return; _finish(pendingId, 'Your PDF is ready. I created a formatted document from the generated content.', filePath: path, fileType: 'pdf', model: 'document'); return; }
      if (_looksLikeZip(text)) { final artifact = await _createProjectZip(text); await ticker.cancel(); if (!mounted) return; _finish(pendingId, artifact.$2, filePath: artifact.$1, fileType: 'zip', model: 'code'); return; }
      final history = _messages.where((m) => !m.pending && m.content.isNotEmpty).take(_messages.length - 2).map((m) => ChatTurn(role: m.role, content: m.content)).toList();
      final result = await AiService(onStep: (step) { if (mounted) setState(() => _live = step.label); }).chat(message: prompt, history: history, grade: widget.grade, web: true);
      await ticker.cancel(); if (!mounted) return;
      _finish(pendingId, result.ok ? result.text : (result.error ?? 'Failed'), steps: result.steps, sources: result.sources, durationMs: result.durationMs, model: result.model);
    } catch (e) { await ticker.cancel(); if (!mounted) return; _finish(pendingId, 'I could not complete that action.\n\n' + e.toString(), model: 'error'); }
  }

  void _finish(String id, String content, {List<ActivityStep> steps = const [], List<WebSource> sources = const [], int? durationMs, String? model, String? imageUrl, String? filePath, String? fileType}) {
    setState(() { _busy = false; final i = _messages.indexWhere((m) => m.id == id); if (i >= 0) { _messages[i] = ChatMessage(id: id, role: 'assistant', content: content, steps: steps, sources: sources, durationMs: durationMs, model: model, imageUrl: imageUrl, filePath: filePath, fileType: fileType); } });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut); });
  }

  Future<String> _writePdf(String markdown) async {
    final title = _titleFromMarkdown(markdown);
    final doc = pw.Document();
    final paragraphs = markdown.replaceAll(RegExp(r'```[\s\S]*?```'), '').split(RegExp(r'\n{2,}')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(42), header: (context) => pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)), footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('JagX AI  •  Page ' + context.pageNumber.toString(), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600))), build: (context) => [pw.Text(title, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 18), ...paragraphs.map((paragraph) { final clean = paragraph.replaceFirst(RegExp(r'^#{1,6}\s*'), ''); final isHeading = paragraph.startsWith('#'); return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Text(clean, style: pw.TextStyle(fontSize: isHeading ? 16 : 10.5, fontWeight: isHeading ? pw.FontWeight.bold : pw.FontWeight.normal, lineSpacing: 3))); })]));
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safe = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final file = File(dir.path + '/' + (safe.isEmpty ? 'jagx-document' : safe) + '.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _titleFromMarkdown(String text) { final match = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(text); return match?.group(1)?.trim() ?? 'JagX AI Document'; }

  Future<(String, String)> _createProjectZip(String request) async {
    final result = await AiService(onStep: (s) { if (mounted) setState(() => _live = s.label); }).chat(message: 'Create a complete, runnable project package for this request: ' + request + '\nReturn files using EXACTLY this format:\n===FILE: path/to/file.ext===\n<file contents>\nDo not omit required configuration files.', history: const [], grade: gradeById('engineer'), web: true);
    if (!result.ok) throw Exception(result.error ?? 'Could not generate project');
    final matches = RegExp(r'===FILE:\s*(.*?)\s*===\s*\n([\s\S]*?)(?=\n===FILE:|$)').allMatches(result.text);
    if (matches.isEmpty) throw Exception('The AI did not return files in the required package format.');
    final archive = Archive();
    for (final match in matches) { var path = match.group(1)!.trim().replaceAll('\\', '/').replaceAll('../', ''); if (path.isEmpty) continue; final bytes = Uint8List.fromList(match.group(2)!.trimRight().codeUnits); archive.addFile(ArchiveFile('jagx-project/' + path, bytes.length, bytes)); }
    final zipBytes = ZipEncoder().encode(archive);
    final dir = await getTemporaryDirectory();
    final file = File(dir.path + '/jagx-project-' + DateTime.now().millisecondsSinceEpoch.toString() + '.zip');
    await file.writeAsBytes(zipBytes, flush: true);
    return (file.path, 'I packaged the generated project into a ZIP with ' + matches.length.toString() + ' files.');
  }
  void _showTools() {
    showModalBottomSheet<void>(context: context, backgroundColor: JagxColors.surface, showDragHandle: true, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 6, 20, 28), children: [
      const Text('JagX tools', style: TextStyle(color: JagxColors.fg, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Everything stays inside this conversation. Describe what you want and JagX chooses the capability.', style: TextStyle(color: JagxColors.muted, height: 1.4)),
      const SizedBox(height: 14),
      _toolTile(Icons.public, 'Web research', 'Search and read live sources', () { Navigator.pop(context); _input.text = 'Research '; }),
      _toolTile(Icons.image_outlined, 'Generate an image', 'Create artwork, logos and illustrations', () { Navigator.pop(context); _input.text = 'Generate an image of '; }),
      _toolTile(Icons.picture_as_pdf_outlined, 'Create a PDF / storybook', 'Write and package a polished PDF', () { Navigator.pop(context); _input.text = 'Create a PDF storybook about '; }),
      _toolTile(Icons.folder_zip_outlined, 'Build a ZIP project', 'Generate files and package the project', () { Navigator.pop(context); _input.text = 'Create and zip a complete project for '; }),
      _toolTile(Icons.extension_outlined, 'Plugins', 'Connect GitHub, Supabase, email, APIs and more', () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PluginCenterScreen())); }),
    ])));
  }

  Widget _toolTile(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 5), leading: CircleAvatar(backgroundColor: JagxColors.elevated, child: Icon(icon, color: JagxColors.fg)), title: Text(title, style: const TextStyle(color: JagxColors.fg, fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(color: JagxColors.muted)), onTap: onTap);
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
    const hints = ['Research the latest AI news and explain what matters','Generate an image of a futuristic Lagos skyline','Create a PDF storybook about a Nigerian family','Create and zip a complete Flutter app for a todo list'];
    return ListView(padding: const EdgeInsets.fromLTRB(20,48,20,20), children: [
      const Text('What can I help you build?', textAlign: TextAlign.center, style: TextStyle(fontSize:30,fontWeight:FontWeight.w700,color:JagxColors.fg)),
      const SizedBox(height:10),
      const Text('One AI for research, writing, coding, files, images and documents.', textAlign:TextAlign.center, style:TextStyle(color:JagxColors.muted)),
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
          MarkdownBody(data:m.content,styleSheet:MarkdownStyleSheet(p:const TextStyle(color:JagxColors.fg,height:1.58,fontSize:15),h1:const TextStyle(color:JagxColors.fg,fontSize:25,fontWeight:FontWeight.w700),h2:const TextStyle(color:JagxColors.fg,fontSize:20,fontWeight:FontWeight.w700),code:const TextStyle(color:JagxColors.fg,fontFamily:'monospace'))),
          if (m.imageUrl != null) Padding(padding: const EdgeInsets.only(top: 12), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(m.imageUrl!, fit: BoxFit.cover))),
          if (m.filePath != null) Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: [FilledButton.icon(onPressed: () => Share.shareXFiles([XFile(m.filePath!)], subject: 'JagX AI'), icon: const Icon(Icons.ios_share, size: 17), label: Text(m.fileType == 'pdf' ? 'Share PDF' : 'Share ZIP')), if (m.fileType == 'pdf') const SizedBox(width: 8), if (m.fileType == 'pdf') OutlinedButton(onPressed: () async { final bytes = await File(m.filePath!).readAsBytes(); await Printing.sharePdf(bytes: bytes, filename: 'jagx-document.pdf'); }, child: const Text('Open / print'))])),
          if (m.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'SOURCES',
              style: TextStyle(
                color: JagxColors.subtle,
                fontSize: 10,
                letterSpacing: 1.4,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            ...m.sources.map(
              (source) => InkWell(
                onTap: () => launchUrl(
                  Uri.parse(source.url),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: JagxColors.accent,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          source.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: JagxColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                const ActionChip(avatar: Icon(Icons.public, size: 17, color: JagxColors.accent), label: Text('Web'), onPressed: null, backgroundColor: JagxColors.surface, labelStyle: TextStyle(color: JagxColors.fg)),
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
                IconButton(tooltip: 'Tools', onPressed: _busy ? null : _showTools, icon: const Icon(Icons.tune, size: 22, color: JagxColors.muted)),
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
