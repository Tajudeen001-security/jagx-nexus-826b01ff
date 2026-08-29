import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/fast_ai_service.dart';
import '../../core/grades.dart';
import '../../core/vision_service.dart';
import '../../theme/jagx_theme.dart';

class NexusChatScreen extends StatefulWidget {
  final Grade grade;
  final ValueChanged<Grade> onGradeChanged;

  const NexusChatScreen({
    super.key,
    required this.grade,
    required this.onGradeChanged,
  });

  @override
  State<NexusChatScreen> createState() => _NexusChatScreenState();
}

class _Attachment {
  final String name;
  final String mime;
  final Uint8List bytes;

  const _Attachment(this.name, this.mime, this.bytes);
}

class _NexusChatScreenState extends State<NexusChatScreen> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  final attachments = <_Attachment>[];

  bool busy = false;
  String status = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _mimeFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    const types = <String, String>{
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'json': 'application/json',
      'csv': 'text/csv',
    };
    return types[extension] ?? 'application/octet-stream';
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes != null) {
          attachments.add(_Attachment(file.name, _mimeFor(file.name), bytes));
        }
      }
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if ((text.isEmpty && attachments.isEmpty) || busy) return;

    final files = List<_Attachment>.from(attachments);
    final history = messages
        .where((message) =>
            message['role'] == 'user' || message['role'] == 'assistant')
        .map<Map<String, String>>((message) => {
              'role': message['role'] as String,
              'content': message['content'] as String,
            })
        .toList();

    controller.clear();
    attachments.clear();

    setState(() {
      messages.add({
        'role': 'user',
        'content': text.isEmpty ? 'Inspect the attached files.' : text,
        'files': files,
      });
      busy = true;
      status = 'Working…';
    });

    try {
      final imageFiles = files
          .where((file) => file.mime.startsWith('image/'))
          .toList();

      if (imageFiles.isNotEmpty) {
        status = 'Reading the image…';
        if (mounted) setState(() {});

        final image = imageFiles.first;
        final answer = await VisionService.analyze(
          bytes: image.bytes,
          mime: image.mime,
          prompt: text.isEmpty
              ? 'Read and explain this image in detail, including visible text.'
              : text,
        );

        if (!mounted) return;
        setState(() {
          messages.add({
            'role': 'assistant',
            'content': answer,
            'model': 'Vision',
          });
          busy = false;
          status = '';
        });
        return;
      }

      final fileContext = files.map((file) {
        final isText = file.mime.startsWith('text/') ||
            file.mime == 'application/json' ||
            file.mime == 'text/csv';
        if (isText) {
          return '\nFILE ${file.name}:\n${String.fromCharCodes(file.bytes)}';
        }
        return '\nATTACHED FILE: ${file.name} (${file.mime})';
      }).join();

      final prompt = '${text.isEmpty ? 'Inspect the attached files.' : text}'
          '$fileContext';

      final result = await FastAiService.complete(
        message: prompt,
        history: history,
        coding: _isCoding,
        onProgress: (progress) {
          if (mounted) setState(() => status = progress);
        },
      );

      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': result.text,
          'model': '${result.provider} • ${result.model}',
        });
        busy = false;
        status = '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': 'I could not complete that request.\n\n$error',
        });
        busy = false;
        status = '';
      });
    }
  }

  bool get _isCoding =>
      widget.grade.id == 'engineer' ||
      widget.grade.id == 'operator' ||
      widget.grade.id == 'coder-fast';

  Future<void> _saveAndShareImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/jagx-generated-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Generated by JagX AI',
    );
  }

  void _showModes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JagxColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'AI modes',
            style: TextStyle(
              color: JagxColors.fg,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...grades.map(
            (grade) => ListTile(
              title: Text(
                grade.label,
                style: const TextStyle(color: JagxColors.fg),
              ),
              subtitle: Text(
                grade.blurb,
                style: const TextStyle(color: JagxColors.muted),
              ),
              trailing: grade.id == widget.grade.id
                  ? const Icon(Icons.check, color: JagxColors.accent)
                  : null,
              onTap: () {
                Navigator.pop(sheetContext);
                widget.onGradeChanged(grade);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final user = message['role'] == 'user';
    final files = (message['files'] as List<_Attachment>?) ??
        const <_Attachment>[];
    final imageBytes = message['imageBytes'];
    final imagePath = message['imagePath'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Align(
        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: user ? JagxColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user && files.isNotEmpty)
                Text(
                  '${files.length} attachment(s)',
                  style: const TextStyle(
                    color: JagxColors.muted,
                    fontSize: 11,
                  ),
                ),
              if (!user && message['model'] != null)
                Text(
                  message['model'] as String,
                  style: const TextStyle(
                    color: JagxColors.subtle,
                    fontSize: 10,
                  ),
                ),
              SelectableText(
                message['content'] as String,
                style: const TextStyle(
                  color: JagxColors.fg,
                  height: 1.5,
                ),
              ),
              if (imageBytes is Uint8List)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.memory(imageBytes),
                ),
              if (imagePath is String)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () async {
                      final bytes = await File(imagePath).readAsBytes();
                      if (mounted) await _saveAndShareImage(bytes);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Save / share image'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const SizedBox.expand()
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _messageBubble(messages[index]),
                ),
        ),
        if (busy)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              status.isEmpty ? 'Working…' : status,
              style: const TextStyle(
                color: JagxColors.muted,
                fontSize: 12,
              ),
            ),
          ),
        if (attachments.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: attachments.map((attachment) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: busy
                        ? null
                        : () => setState(
                              () => attachments.remove(attachment),
                            ),
                  ),
                );
              }).toList(),
            ),
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
                children: [
                  IconButton(
                    onPressed: busy ? null : _pickFiles,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: JagxColors.fg,
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : _showModes,
                    icon: const Icon(
                      Icons.tune,
                      color: JagxColors.muted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: busy ? null : _send,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
