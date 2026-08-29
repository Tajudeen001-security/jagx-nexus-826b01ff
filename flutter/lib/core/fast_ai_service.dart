import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class FastAiResult {
  final String text;
  final String model;
  final String provider;
  final int durationMs;
  const FastAiResult({required this.text, required this.model, required this.provider, required this.durationMs});
}

class FastAiService {
  static final http.Client _client = http.Client();

  static List<_Provider> _providers({bool coding = false}) {
    final out = <_Provider>[];
    if (AppConfig.groqApiKey.isNotEmpty) {
      out.add(_Provider('Groq', AppConfig.groqBase, AppConfig.groqApiKey, coding ? 'openai/gpt-oss-120b' : 'llama-3.1-8b-instant'));
    }
    if (AppConfig.nvidiaApiKey.isNotEmpty) {
      out.add(_Provider('NVIDIA', AppConfig.nvidiaBase, AppConfig.nvidiaApiKey, coding ? 'qwen/qwen2.5-coder-32b-instruct' : 'qwen/qwen3-next-80b-a3b-instruct'));
    }
    if (AppConfig.openRouterApiKey.isNotEmpty) {
      out.add(_Provider('OpenRouter', AppConfig.openRouterBase, AppConfig.openRouterApiKey, coding ? 'qwen/qwen-2.5-coder-32b-instruct' : 'openrouter/free', extra: const {'HTTP-Referer':'https://www.jagxai.name.ng','X-Title':'JagX AI'}));
    }
    if (AppConfig.jagxApiKey.isNotEmpty && AppConfig.jagxApiBaseUrl.isNotEmpty) {
      out.add(_Provider('JagX API', AppConfig.jagxApiBaseUrl, AppConfig.jagxApiKey, coding ? 'coding' : 'fast'));
    }
    if (AppConfig.openAiApiKey.isNotEmpty) {
      out.add(_Provider('OpenAI', AppConfig.openAiBase, AppConfig.openAiApiKey, coding ? 'gpt-5' : 'gpt-5-mini'));
    }
    return out;
  }

  static Future<FastAiResult> complete({required String message, List<Map<String,String>> history = const [], bool coding = false, int maxTokens = 1800, void Function(String)? onProgress}) async {
    final providers = _providers(coding: coding);
    if (providers.isEmpty) throw Exception('No AI provider is configured.');
    final messages = <Map<String,String>>[
      {'role':'system','content': coding ? 'You are JagX AI Coding mode. Work carefully, verify assumptions, and prioritize correctness over speed. Explain the work as you go.' : 'You are JagX AI. Be fast, direct, useful and multifunctional. Do not ask what the user wants when the request is already clear.'},
      ...history.take(8),
      {'role':'user','content':message},
    ];
    final started = DateTime.now();
    onProgress?.call(coding ? 'Planning the implementation' : 'Routing to the fastest available model');
    if (coding) {
      Object? last;
      for (final p in providers) {
        try { onProgress?.call('Working with ${p.name}'); return await _call(p, messages, maxTokens, started); } catch(e) { last=e; }
      }
      throw Exception(last ?? 'All coding providers failed.');
    }
    final futures = providers.map((p) async {
      try { return await _call(p, messages, maxTokens, started); } catch (_) { return null; }
    }).toList();
    final result = await _firstSuccessful(futures);
    if (result == null) throw Exception('All AI providers failed.');
    return result;
  }

  static Future<FastAiResult?> _firstSuccessful(List<Future<FastAiResult?>> futures) async {
    final completer = Completer<FastAiResult?>();
    var remaining = futures.length;
    for (final f in futures) {
      f.then((value) { if (value != null && !completer.isCompleted) completer.complete(value); else { remaining--; if (remaining == 0 && !completer.isCompleted) completer.complete(null); } }).catchError((_) { remaining--; if (remaining == 0 && !completer.isCompleted) completer.complete(null); return null; });
    }
    return completer.future;
  }

  static Future<FastAiResult> _call(_Provider p, List<Map<String,String>> messages, int maxTokens, DateTime started) async {
    final res = await _client.post(Uri.parse('${p.base}/chat/completions'), headers:{'Content-Type':'application/json','Authorization':'Bearer ${p.key}',...?p.extra}, body:jsonEncode({'model':p.model,'messages':messages,'max_tokens':maxTokens,'temperature':0.4})).timeout(const Duration(seconds:18));
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('${p.name} ${res.statusCode}: ${res.body}');
    final data=jsonDecode(res.body) as Map<String,dynamic>;
    final choices=data['choices'] as List<dynamic>?;
    if (choices==null || choices.isEmpty) throw Exception('${p.name} returned no choices');
    final msg=(choices.first as Map)['message'] as Map?;
    final text=msg?['content']?.toString() ?? '';
    if (text.trim().isEmpty) throw Exception('${p.name} returned empty text');
    return FastAiResult(text:text,model:data['model']?.toString()??p.model,provider:p.name,durationMs:DateTime.now().difference(started).inMilliseconds);
  }
}

class _Provider {
  final String name, base, key, model;
  final Map<String,String>? extra;
  const _Provider(this.name,this.base,this.key,this.model,{this.extra});
}
