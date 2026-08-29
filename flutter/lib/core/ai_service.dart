import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'grades.dart';

class ActivityStep {
  final String id;
  final String label;
  final String? detail;
  const ActivityStep({required this.id, required this.label, this.detail});
}

class WebSource {
  final String title;
  final String url;
  final String snippet;
  const WebSource({required this.title, required this.url, required this.snippet});
}

class ChatTurn {
  final String role;
  final String content;
  const ChatTurn({required this.role, required this.content});
}

class ChatResult {
  final bool ok;
  final String text;
  final String? error;
  final List<ActivityStep> steps;
  final List<WebSource> sources;
  final int durationMs;
  final String model;
  const ChatResult({
    required this.ok,
    required this.text,
    this.error,
    required this.steps,
    required this.sources,
    required this.durationMs,
    required this.model,
  });
}

class StreamChunk {
  final String? delta;
  final ActivityStep? step;
  final bool done;
  final ChatResult? result;
  const StreamChunk({this.delta, this.step, this.done = false, this.result});
}

class AiService {
  final void Function(ActivityStep step)? onStep;
  AiService({this.onStep});

  void _step(String id, String label, [String? detail]) {
    onStep?.call(ActivityStep(id: id, label: label, detail: detail));
  }

  Future<List<WebSource>> searchWeb(String query, {int limit = 5}) async {
    _step('search', 'Searching the live web');
    try {
      final uri = Uri.parse(
          'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri, headers: {
        'user-agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        'accept': 'text/html',
      });
      if (res.statusCode != 200) return [];
      final out = <WebSource>[];
      final blocks = res.body.split('result__body').skip(1).take(limit);
      for (final b in blocks) {
        final titleMatch =
            RegExp(r'class="result__a"[^>]*>([\s\S]*?)</a>').firstMatch(b);
        final hrefMatch =
            RegExp(r'href="([^"]+)"').firstMatch(titleMatch?.group(0) ?? '');
        if (titleMatch == null || hrefMatch == null) continue;
        var url = (hrefMatch.group(1) ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
        final uddg = RegExp(r'uddg=([^&]+)').firstMatch(url);
        if (uddg != null) url = Uri.decodeComponent(uddg.group(1)!);
        if (url.startsWith('//')) url = 'https:$url';
        out.add(WebSource(
          title: titleMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          url: url,
          snippet: '',
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<ChatResult> chat({
    required String message,
    required List<ChatTurn> history,
    required Grade grade,
    bool web = true,
  }) async {
    ChatResult? finalResult;
    await for (final c in chatStream(
        message: message, history: history, grade: grade, web: web)) {
      if (c.done && c.result != null) finalResult = c.result;
    }
    return finalResult ??
        ChatResult(
          ok: false,
          text: '',
          error: 'No response',
          steps: const [],
          sources: const [],
          durationMs: 0,
          model: 'error',
        );
  }

  Stream<StreamChunk> chatStream({
    required String message,
    required List<ChatTurn> history,
    required Grade grade,
    bool web = true,
  }) async* {
    final started = DateTime.now();
    final steps = <ActivityStep>[];
    ActivityStep push(String id, String label, [String? detail]) {
      final s = ActivityStep(id: id, label: label, detail: detail);
      steps.add(s);
      onStep?.call(s);
      return s;
    }

    yield StreamChunk(step: push('think', 'Reading the request'));
    var sources = <WebSource>[];
    var extra = '';
    if (web ||
        RegExp(r'\b(today|latest|news|search|web|google)\b',
                caseSensitive: false)
            .hasMatch(message)) {
      yield StreamChunk(step: push('search', 'Searching the live web'));
      sources = await searchWeb(message);
      if (sources.isNotEmpty) {
        yield StreamChunk(
            step: push('read', 'Opening top source', sources.first.title));
        extra = '\n\nLIVE WEB:\n' +
            sources
                .asMap()
                .entries
                .map((e) => '[${e.key + 1}] ${e.value.title}\n${e.value.url}')
                .join('\n');
      }
    }
    yield StreamChunk(step: push('compose', 'Writing answer'));

    if (!AppConfig.hasAnyLlmKey) {
      yield StreamChunk(
        done: true,
        result: ChatResult(
          ok: false,
          text: '',
          error: 'AI provider keys are not configured.',
          steps: steps,
          sources: sources,
          durationMs: DateTime.now().difference(started).inMilliseconds,
          model: 'offline',
        ),
      );
      return;
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            '${grade.system}\nYou are JagX AI ${AppConfig.version} by JagX & JRILICENSE.',
      },
      ...history.take(12).map((t) => {'role': t.role, 'content': t.content}),
      {'role': 'user', 'content': message + extra},
    ];

    try {
      final buffer = StringBuffer();
      String modelUsed = 'unknown';
      await for (final piece in _streamComplete(messages, grade.maxTokens)) {
        if (piece.startsWith('__MODEL__:')) {
          modelUsed = piece.substring(10);
          continue;
        }
        buffer.write(piece);
        yield StreamChunk(delta: piece);
      }
      yield StreamChunk(step: push('done', 'Answer ready'));
      yield StreamChunk(
        done: true,
        result: ChatResult(
          ok: true,
          text: buffer.toString(),
          steps: steps,
          sources: sources,
          durationMs: DateTime.now().difference(started).inMilliseconds,
          model: modelUsed,
        ),
      );
    } catch (e) {
      try {
        final result = await _complete(messages, grade.maxTokens);
        yield StreamChunk(delta: result.$1);
        yield StreamChunk(step: push('done', 'Answer ready'));
        yield StreamChunk(
          done: true,
          result: ChatResult(
            ok: true,
            text: result.$1,
            steps: steps,
            sources: sources,
            durationMs: DateTime.now().difference(started).inMilliseconds,
            model: result.$2,
          ),
        );
      } catch (e2) {
        yield StreamChunk(
          done: true,
          result: ChatResult(
            ok: false,
            text: '',
            error: e2.toString(),
            steps: steps,
            sources: sources,
            durationMs: DateTime.now().difference(started).inMilliseconds,
            model: 'error',
          ),
        );
      }
    }
  }

  Future<(String, String)> _complete(
    List<Map<String, String>> messages,
    int maxTokens,
  ) async {
    Object? lastError;
    for (final p in _providers()) {
      try {
        return await _openAi(
          p.$1,
          p.$2,
          p.$3,
          messages,
          maxTokens,
          extra: p.$4,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception(lastError ?? 'All AI providers failed.');
  }

  Stream<String> _streamComplete(
    List<Map<String, String>> messages,
    int maxTokens,
  ) async* {
    Object? lastError;
    for (final p in _providers()) {
      final client = http.Client();
      var emitted = false;
      var model = p.$3;
      try {
        final req = http.Request(
          'POST',
          Uri.parse('${p.$1}/chat/completions'),
        );
        req.headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${p.$2}',
          'Accept': 'text/event-stream',
          ...?p.$4,
        });
        req.body = jsonEncode({
          'model': p.$3,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.5,
          'stream': true,
        });
        final streamed = await client.send(req).timeout(
          const Duration(seconds: 45),
        );
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          final body = await streamed.stream.bytesToString();
          throw Exception('LLM ${streamed.statusCode}: $body');
        }
        yield '__MODEL__:$model';
        await for (final line in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') break;
          try {
            final map = jsonDecode(data) as Map<String, dynamic>;
            final choices = map['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = (choices.first as Map)['delta'] as Map?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              emitted = true;
              yield content;
            }
            final m = map['model'] as String?;
            if (m != null) model = m;
          } catch (_) {}
        }
        return;
      } catch (e) {
        lastError = e;
        if (emitted) rethrow;
      } finally {
        client.close();
      }
    }
    throw Exception(lastError ?? 'All AI providers failed.');
  }

  List<(String, String, String, Map<String, String>?)> _providers() {
    final providers = <(String, String, String, Map<String, String>?)>[];
    if (AppConfig.nvidiaApiKey.isNotEmpty) {
      providers.add((
        AppConfig.nvidiaBase,
        AppConfig.nvidiaApiKey,
        'nvidia/nemotron-3.5-lightning-30b-a3b',
        null,
      ));
    }
    if (AppConfig.openRouterApiKey.isNotEmpty) {
      providers.add((
        AppConfig.openRouterBase,
        AppConfig.openRouterApiKey,
        'openrouter/free',
        {
          'HTTP-Referer': 'https://www.jagxai.name.ng',
          'X-Title': 'JagX AI',
        },
      ));
    }
    return providers;
  }

  Future<(String, String)> _openAi(
    String base,
    String key,
    String model,
    List<Map<String, String>> messages,
    int maxTokens, {
    Map<String, String>? extra,
  }) async {
    final res = await http.post(
      Uri.parse('$base/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        ...?extra,
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': 0.5,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('LLM ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final text = choices != null && choices.isNotEmpty
        ? ((choices.first as Map)['message'] as Map)['content'] as String? ??
            ''
        : '';
    return (text, data['model'] as String? ?? model);
  }

  Future<String> generateBook({required String topic, int chapters = 6}) async {
    final r = await chat(
      message:
          'Write a ${chapters.clamp(3, 12)}-chapter Markdown book on: $topic\n'
          'Use # for title, ## for chapters. Include a short preface.',
      history: const [],
      grade: gradeById('scholar'),
      web: false,
    );
    if (!r.ok) throw Exception(r.error ?? 'Book failed');
    return r.text;
  }

  Future<String> analyzeCode(String code, {String language = 'dart'}) async {
    final r = await chat(
      message:
          'Analyze this $language code. Report bugs, complexity, and a short improved version if needed:\n\n```$language\n$code\n```',
      history: const [],
      grade: gradeById('engineer'),
      web: false,
    );
    if (!r.ok) throw Exception(r.error ?? 'Analyze failed');
    return r.text;
  }

  Future<String?> generateImageUrl(String prompt) async {
    _step('image', 'Generating image');
    final encoded = Uri.encodeComponent(prompt.trim());
    final seed = prompt.hashCode.abs() % 100000;
    return 'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&seed=$seed';
  }
}
