import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'config.dart';

class VisionService {
  static final http.Client _client = http.Client();

  static String _dataUrl(Uint8List bytes, String mime) => 'data:$mime;base64,${base64Encode(bytes)}';

  static Future<String> analyze({required Uint8List bytes, required String mime, required String prompt}) async {
    final image = _dataUrl(bytes,mime);
    final providers = <Map<String,String>>[];
    if (AppConfig.groqApiKey.isNotEmpty) providers.add({'base':AppConfig.groqBase,'key':AppConfig.groqApiKey,'model':'meta-llama/llama-4-scout-17b-16e-instruct'});
    if (AppConfig.openRouterApiKey.isNotEmpty) providers.add({'base':AppConfig.openRouterBase,'key':AppConfig.openRouterApiKey,'model':'google/gemini-2.0-flash-001'});
    if (AppConfig.nvidiaApiKey.isNotEmpty) providers.add({'base':AppConfig.nvidiaBase,'key':AppConfig.nvidiaApiKey,'model':'meta/llama-3.2-11b-vision-instruct'});
    Object? last;
    for(final p in providers){
      try{
        final res=await _client.post(Uri.parse('${p['base']}/chat/completions'),headers:{'Content-Type':'application/json','Authorization':'Bearer ${p['key']}'},body:jsonEncode({'model':p['model'],'messages':[{'role':'user','content':[{'type':'text','text':prompt},{'type':'image_url','image_url':{'url':image}}]}],'max_tokens':1800,'temperature':0.2})).timeout(const Duration(seconds:20));
        if(res.statusCode<200||res.statusCode>=300) throw Exception('${p['model']} ${res.statusCode}');
        final data=jsonDecode(res.body) as Map<String,dynamic>; final choices=data['choices'] as List<dynamic>?; final msg=choices?.isNotEmpty==true?(choices!.first as Map)['message'] as Map?:null; final text=msg?['content']?.toString()??''; if(text.trim().isEmpty) throw Exception('Empty vision response'); return text;
      }catch(e){last=e;}
    }
    throw Exception(last??'No vision provider configured.');
  }

  static Future<Uint8List> editWithOpenAI({required Uint8List bytes, required String mime, required String prompt}) async {
    if(AppConfig.openAiApiKey.isEmpty) throw Exception('OPENAI_API_KEY is not configured for image editing.');
    final request=http.MultipartRequest('POST',Uri.parse('${AppConfig.openAiBase}/images/edits'));
    request.headers['Authorization']='Bearer ${AppConfig.openAiApiKey}';
    request.fields['model']='gpt-image-1';
    request.fields['prompt']=prompt;
    request.files.add(http.MultipartFile.fromBytes('image',bytes,filename:mime.contains('png')?'input.png':'input.jpg'));
    final response=await request.send().timeout(const Duration(seconds:60));
    final body=await response.stream.bytesToString();
    if(response.statusCode<200||response.statusCode>=300) throw Exception('Image edit ${response.statusCode}: $body');
    final data=jsonDecode(body) as Map<String,dynamic>; final item=(data['data'] as List<dynamic>).first as Map<String,dynamic>; final b64=item['b64_json']?.toString(); if(b64==null) throw Exception('Image editor returned no image bytes'); return base64Decode(b64);
  }
}
