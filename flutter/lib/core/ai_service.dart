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
    final started = DateTime.now();
    final steps = <ActivityStep>[];
    void push(String id, String label, [String? detail]) {
      final s = ActivityStep(id: id, label: label, detail: detail);
      steps.add(s);
      onStep?.call(s);
    }

    push('think', 'Reading the request');
    var sources = <WebSource>[];
    var extra = '';
    if (web ||
        RegExp(r'\b(today|latest|news|search|web|google)\b',
                caseSensitive: false)
            .hasMatch(message)) {
      sources = await searchWeb(message);
      if (sources.isNotEmpty) {
        push('read', 'Opening top source', sources.first.title);
        extra = '\n\nLIVE WEB:\n' +
            sources
                .asMap()
                .entries
                .map((e) => '[${e.key + 1}] ${e.value.title}\n${e.value.url}')
                .join('\n');
      }
    }
    push('compose', 'Composing the answer');
    if (!AppConfig.hasAnyLlmKey) {
      return ChatResult(
        ok: false,
        text: '',
        error:
            'Add a key: OPENROUTER_API_KEY, KIMI_API_KEY, NVIDIA_API_KEY, or GROQ_API_KEY',
        steps: steps,
        sources: sources,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        model: 'offline',
      );
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
      final result = await _complete(messages, grade.maxTokens);
      push('done', 'Answer ready');
      return ChatResult(
        ok: true,
        text: result.$1,
        steps: steps,
        sources: sources,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        model: result.$2,
      );
    } catch (e) {
      return ChatResult(
        ok: false,
        text: '',
        error: e.toString(),
        steps: steps,
        sources: sources,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        model: 'error',
      );
    }
  }

  /// Priority: OpenRouter → Kimi → NVIDIA → Groq
  Future<(String, String)> _complete(
    List<Map<String, String>> messages,
    int maxTokens,
  ) async {
    if (AppConfig.openRouterApiKey.isNotEmpty) {
      return _openAi(
        AppConfig.openRouterBase,
        AppConfig.openRouterApiKey,
        // Prefer free routes when available; OpenRouter will fall through paid if needed.
        'moonshotai/kimi-k2:free',
        messages,
        maxTokens,
        extra: {
          'HTTP-Referer': 'https://www.jagxai.name.ng',
          'X-Title': 'JagX AI',
        },
      );
    }
    if (AppConfig.effectiveKimiKey.isNotEmpty) {
      return _openAi(
        AppConfig.kimiBase,
        AppConfig.effectiveKimiKey,
        'kimi-k2.6',
        messages,
        maxTokens,
      );
    }
    if (AppConfig.nvidiaApiKey.isNotEmpty) {
      return _openAi(
        AppConfig.nvidiaBase,
        AppConfig.nvidiaApiKey,
        'meta/llama-3.1-70b-instruct',
        messages,
        maxTokens,
      );
    }
    return _openAi(
      AppConfig.groqBase,
      AppConfig.groqApiKey,
      'llama-3.3-70b-versatile',
      messages,
      maxTokens,
    );
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

  /// Free image gen via Pollinations (no API key).
  Future<String?> generateImageUrl(String prompt) async {
    _step('image', 'Generating image');
    final encoded = Uri.encodeComponent(prompt.trim());
    // Deterministic seed from prompt length for cache-friendly URLs.
    final seed = prompt.hashCode.abs() % 100000;
    return 'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&seed=$seed';
  }
}
