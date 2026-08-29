import '../../core/ai_service.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final List<ActivityStep> steps;
  final List<WebSource> sources;
  final int? durationMs;
  final String? model;
  final bool pending;
  final String? imageUrl;
  final String? filePath;
  final String? fileType;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.steps = const [],
    this.sources = const [],
    this.durationMs,
    this.model,
    this.pending = false,
    this.imageUrl,
    this.filePath,
    this.fileType,
  });
}
