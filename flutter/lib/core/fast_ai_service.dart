import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class FastAiResult {
  final String text;
  final String model;
  final String provider;
  final int durationMs;
  const FastAiResult({
    required this.text,
    required this.model,
    required this.provider,
    required this.durationMs,
  });
}

class FastStreamEvent {
  final String? delta;
  final String? status;
  final FastAiResult? result;
  const FastStreamEvent({this.delta, this.status, this.result});
}

class FastAiService {
  static final http.Client _client = http.Client();

  static List<_Provider> _providers({bool coding = false}) {
    final out = <_Provider>[];
    if (AppConfig.groqApiKey.isNotEmpty) {
      out.add(_Provider(
        'Groq',
        AppConfig.groqBase,
        AppConfig.groqApiKey,
        coding ? 'llama-3.3-70b-versatile' : 'llama-3.1-8b-instant',
      ));
    }
    if (AppConfig.nvidiaApiKey.isNotEmpty) {
      out.add(_Provider(
        'NVIDIA',
        AppConfig.nvidiaBase,
        AppConfig.nvidiaApiKey,
        coding
            ? 'qwen/qwen2.5-coder-32b-instruct'
            : 'meta/llama-3.1-8b-instruct',
      ));
    }
    if (AppConfig.openRouterApiKey.isNotEmpty) {
      out.add(_Provider(
        'OpenRouter',
        AppConfig.openRouterBase,
        AppConfig.openRouterApiKey,
        coding
            ? 'qwen/qwen-2.5-coder-32b-instruct'
            : 'meta-llama/llama-3.1-8b-instruct:free',
        extra: const {
          'HTTP-Referer': 'https://www.jagxai.name.ng',
          'X-Title': 'JagX AI',
        },
      ));
    }
    if (AppConfig.kimiApiKey.isNotEmpty) {
      out.add(_Provider(
        'Kimi',
        AppConfig.kimiBase,
        AppConfig.kimiApiKey,
        'kimi-k2.6',
      ));
    }
    if (AppConfig.jagxApiKey.isNotEmpty && AppConfig.jagxApiBaseUrl.isNotEmpty) {
      out.add(_Provider(
        'JagX API',
        AppConfig.jagxApiBaseUrl,
        AppConfig.jagxApiKey,
        coding ? 'coding' : 'fast',
      ));
    }
    if (AppConfig.openAiApiKey.isNotEmpty) {
      out.add(_Provider(
        'OpenAI',
        AppConfig.openAiBase,
        AppConfig.openAiApiKey,
        coding ? 'gpt-4o-mini' : 'gpt-4o-mini',
      ));
    }
    return out;
  }

  static Future<FastAiResult> complete({
    required String message,
    List<Map<String, String>> history = const [],
    bool coding = false,
    int maxTokens = 1200,
    void Function(String)? onProgress,
  }) async {
    final buffer = StringBuffer();
    FastAiResult? done;
    await for (final event in stream(
      message: message,
      history: history,
      coding: coding,
      maxTokens: maxTokens,
    )) {
      if (event.status != null) onProgress?.call(event.status!);
      if (event.delta != null) buffer.write(event.delta);
      if (event.result != null) done = event.result;
    }
    if (done != null) return done;
    throw Exception('No AI provider is configured.');
  }

  static Stream<FastStreamEvent> stream({
    required String message,
    List<Map<String, String>> history = const [],
    bool coding = false,
    int maxTokens = 1200,
  }) async* {
    final providers = _providers(coding: coding);
    if (providers.isEmpty) {
      throw Exception('No AI provider is configured.');
    }
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': coding
            ? 'You are JagX AI Coding. Ship correct runnable code. Be concise.'
            : 'You are JagX AI. Be fast, direct and useful. Do not stall or over-ask.',
      },
      ...history.take(6),
      {'role': 'user', 'content': message},
    ];
    final started = DateTime.now();
    yield FastStreamEvent(status: 'Connecting to ${providers.first.name}');
    Object? last;
    for (final p in providers) {
      try {
        yield FastStreamEvent(status: 'Writing with ${p.name}');
        final buffer = StringBuffer();
        await for (final delta in _streamCall(p, messages, maxTokens)) {
          buffer.write(delta);
          yield FastStreamEvent(delta: delta);
        }
        final text = buffer.toString();
        if (text.trim().isEmpty) throw Exception('${p.name} returned empty text');
        yield FastStreamEvent(
          result: FastAiResult(
            text: text,
            model: p.model,
            provider: p.name,
            durationMs: DateTime.now().difference(started).inMilliseconds,
          ),
        );
        return;
      } catch (e) {
        last = e;
        yield FastStreamEvent(status: '${p.name} failed, trying next');
      }
    }
    throw Exception(last ?? 'All AI providers failed.');
  }

  static Stream<String> _streamCall(
    _Provider p,
    List<Map<String, String>> messages,
    int maxTokens,
  ) async* {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse('${p.base}/chat/completions'));
      req.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${p.key}',
        'Accept': 'text/event-stream',
        ...?p.extra,
      });
      req.body = jsonEncode({
        'model': p.model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': 0.4,
        'stream': true,
      });
      final streamed = await client.send(req).timeout(const Duration(seconds: 20));
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        throw Exception('${p.name} ${streamed.statusCode}: $body');
      }
      var emitted = false;
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
        } catch (_) {}
      }
      if (!emitted) {
        final fallback = await _call(p, messages, maxTokens, DateTime.now());
        yield fallback.text;
      }
    } finally {
      client.close();
    }
  }

  static Future<FastAiResult> _call(
    _Provider p,
    List<Map<String, String>> messages,
    int maxTokens,
    DateTime started,
  ) async {
    final res = await _client
        .post(
          Uri.parse('${p.base}/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${p.key}',
            ...?p.extra,
          },
          body: jsonEncode({
            'model': p.model,
            'messages': messages,
            'max_tokens': maxTokens,
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 18));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('${p.name} ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('${p.name} returned no choices');
    }
    final msg = (choices.first as Map)['message'] as Map?;
    final text = msg?['content']?.toString() ?? '';
    if (text.trim().isEmpty) throw Exception('${p.name} returned empty text');
    return FastAiResult(
      text: text,
      model: data['model']?.toString() ?? p.model,
      provider: p.name,
      durationMs: DateTime.now().difference(started).inMilliseconds,
    );
  }
}

class _Provider {
  final String name, base, key, model;
  final Map<String, String>? extra;
  const _Provider(this.name, this.base, this.key, this.model, {this.extra});
}
