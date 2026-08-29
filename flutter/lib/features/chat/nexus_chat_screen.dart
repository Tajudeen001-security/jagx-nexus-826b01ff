import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/fast_ai_service.dart';
import '../../core/vision_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';

class NexusChatScreen extends StatefulWidget {
  final Grade grade;
  final ValueChanged<Grade> onGradeChanged;
  const NexusChatScreen({super.key, required this.grade, required this.onGradeChanged});
  @override State<NexusChatScreen> createState()=>_NexusChatScreenState();
}

class _NexusAttachment { final String name, mime; final Uint8List bytes; const _NexusAttachment({required this.name,required this.mime,required this.bytes}); }
class _NexusMessage { final String id, role, text; final bool pending; final String? model; final Uint8List? image; const _NexusMessage({required this.id,required this.role,required this.text,this.pending=false,this.model,this.image}); }

class _NexusChatScreenState extends State<NexusChatScreen>{
  final _input=TextEditingController(); final _scroll=ScrollController(); final _uuid=const Uuid();
  final List<_NexusMessage> _messages=[]; final List<_NexusAttachment> _attachments=[];
  bool _busy=false; bool _coding=false; String _status=''; String? _locationContext;

  @override void dispose(){_input.dispose();_scroll.dispose();super.dispose();}

  String _mime(String ext){const m={'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif','pdf':'application/pdf','txt':'text/plain','md':'text/markdown','json':'application/json','dart':'text/plain','kt':'text/plain','java':'text/plain','js':'text/plain','ts':'text/plain','tsx':'text/plain','py':'text/plain','go':'text/plain','rs':'text/plain','csv':'text/csv'};return m[ext.toLowerCase()]??'application/octet-stream';}
  bool _isImage(_NexusAttachment a)=>a.mime.startsWith('image/');
  bool _looksLikeImageGeneration(String t)=>RegExp(r'\b(generate|create|draw|make|design)\b[\s\S]*\b(image|picture|logo|poster|illustration|wallpaper)\b',caseSensitive:false).hasMatch(t);
  bool _looksLikeEdit(String t)=>RegExp(r'\b(edit|retouch|remove|erase|replace|change|fix|enhance|restore|crop|background)\b',caseSensitive:false).hasMatch(t);

  Future<void> _pick() async{
    final r=await FilePicker.platform.pickFiles(allowMultiple:true,withData:true);
    if(r==null||!mounted)return;
    setState((){for(final f in r.files){if(_attachments.length>=10)break;if(f.bytes!=null)_attachments.add(_NexusAttachment(name:f.name,mime:_mime(f.extension??''),bytes:f.bytes!));}});
  }

  Future<void> _location() async{
    setState(()=>_status='Getting your current location…');
    var enabled=await Geolocator.isLocationServiceEnabled();
    if(!enabled){setState(()=>_status='Turn on location services to use live maps.');return;}
    var permission=await Geolocator.checkPermission();
    if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
    if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){setState(()=>_status='Location permission was not granted.');return;}
    final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));
    final link='https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}';
    setState((){_locationContext='${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';_status='Live location ready';});
    await launchUrl(Uri.parse(link),mode:LaunchMode.externalApplication);
  }

  Future<void> _send() async{
    final text=_input.text.trim(); if((text.isEmpty&&_attachments.isEmpty)||_busy)return;
    final attachments=List<_NexusAttachment>.from(_attachments); _input.clear(); _attachments.clear();
    final userText=text.isEmpty?'Inspect the attached files.':text;
    setState((){_busy=true;_status=_coding?'Planning and verifying the code…':'Routing to the fastest model…';_messages.add(_NexusMessage(id:_uuid.v4(),role:'user',text:userText));_messages.add(_NexusMessage(id:_uuid.v4(),role:'assistant',text:'',pending:true));});
    final pending=_messages.last.id;
    try{
      final image=attachments.where(_isImage).cast<_NexusAttachment?>().firstWhere((x)=>x!=null,orElse:()=>null);
      if(image!=null){
        final request=_looksLikeEdit(text)?'Edit this image exactly as requested. Preserve the subject and composition unless the request says otherwise. $text':'Describe the image in detail, including visible text, objects, layout, UI elements, errors and anything useful to the user. $text';
        if(_looksLikeEdit(text)){
          setState(()=>_status='Editing the image…');
          try{final edited=await VisionService.editWithOpenAI(bytes:image!.bytes,mime:image.mime,prompt:request);_finish(pending,'Image edited.',model:'gpt-image-1',image:edited);return;}catch(e){
            setState(()=>_status='Image editor unavailable; analyzing the image instead…');
          }
        }
        setState(()=>_status='Reading the image…');
        final result=await VisionService.analyze(bytes:image!.bytes,mime:image.mime,prompt:request);
        _finish(pending,result,model:'vision');return;
      }
      if(_looksLikeImageGeneration(text)){
        setState(()=>_status='Creating the image…');
        final encoded=Uri.encodeComponent(text); final url='https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true';
        _finish(pending,'Generated image.',model:'image',imageUrl:url);return;
      }
      final docs=attachments.where((a)=>a.mime.startsWith('text/')||a.mime=='application/json'||a.mime=='text/csv');
      final fileContext=docs.map((a)=>'\n\nFILE: ${a.name}\n${String.fromCharCodes(a.bytes)}').join();
      final location=_locationContext==null?'':'\nCurrent location: $_locationContext';
      final history=_messages.where((m)=>m.role!='assistant'||!m.pending).take(_messages.length-2).map((m)=>{'role':m.role,'content':m.text}).toList();
      final result=await FastAiService.complete(message:userText+fileContext+location,history:history,coding:_coding,onProgress:(s){if(mounted)setState(()=>_status=s);});
      _finish(pending,result.text,model:'${result.provider} • ${result.model}');
    }catch(e){_finish(pending,'I could not complete that request.\n\n$e');}
  }

  void _finish(String id,String text,{String? model,Uint8List? image,String? imageUrl}){setState((){_busy=false;_status='';final i=_messages.indexWhere((m)=>m.id==id);if(i>=0)_messages[i]=_NexusMessage(id:id,role:'assistant',text:imageUrl==null?text:'Generated image.',model:model,image:image);});if(imageUrl!=null){setState(()=>_status=imageUrl);}
    WidgetsBinding.instance.addPostFrameCallback((_) {if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
  }

  void _mode(){showModalBottomSheet(context:context,backgroundColor:JagxColors.surface,showDragHandle:true,builder:(_)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[const Text('AI modes',style:TextStyle(color:JagxColors.fg,fontSize:22,fontWeight:FontWeight.w700)),const SizedBox(height:8),...grades.map((g)=>ListTile(title:Text(g.label,style:const TextStyle(color:JagxColors.fg)),subtitle:Text(g.blurb,style:const TextStyle(color:JagxColors.muted)),trailing:g.id==widget.grade.id?const Icon(Icons.check,color:JagxColors.accent):null,onTap:(){Navigator.pop(context);widget.onGradeChanged(g);setState(()=>_coding=g.id=='engineer'||g.id=='operator');}))])));}

  @override Widget build(BuildContext context)=>Column(children:[Expanded(child:_messages.isEmpty?_blank():_list()),_composer()]);
  Widget _blank()=>const SizedBox.expand();
  Widget _list()=>ListView.builder(controller:_scroll,padding:const EdgeInsets.fromLTRB(18,24,18,20),itemCount:_messages.length,itemBuilder:(c,i){final m=_messages[i];if(m.role=='user')return Align(alignment:Alignment.centerRight,child:Container(constraints:const BoxConstraints(maxWidth:680),margin:const EdgeInsets.only(bottom:18,left:48),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:JagxColors.elevated,borderRadius:BorderRadius.circular(18)),child:Text(m.text,style:const TextStyle(color:JagxColors.fg)));if(m.pending)return Padding(padding:const EdgeInsets.only(bottom:22),child:Row(children:[const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)),const SizedBox(width:10),Flexible(child:Text(_status.isEmpty?'Working…':_status,style:const TextStyle(color:JagxColors.muted,fontSize:12)))]));return Padding(padding:const EdgeInsets.only(bottom:24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(m.model!=null)Text(m.model!,style:const TextStyle(color:JagxColors.subtle,fontSize:10,fontFamily:'monospace')),const SizedBox(height:4),SelectableText(m.text,style:const TextStyle(color:JagxColors.fg,fontSize:15,height:1.55)),if(m.image!=null)Padding(padding:const EdgeInsets.only(top:12),child:ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.memory(m.image!,fit:BoxFit.contain))),]));});

  Widget _composer()=>SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Container(decoration:BoxDecoration(color:JagxColors.surface,borderRadius:BorderRadius.circular(24),border:Border.all(color:JagxColors.elevated)),padding:const EdgeInsets.fromLTRB(8,6,8,6),child:Column(children:[if(_attachments.isNotEmpty)SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,children:_attachments.map((a)=>Padding(padding:const EdgeInsets.only(right:6),child:Chip(label:Text(a.name,maxLines:1,overflow:TextOverflow.ellipsis),onDeleted:_busy?null:()=>setState(()=>_attachments.remove(a)))).toList())),Row(children:[IconButton(tooltip:'Add image, file or document',onPressed:_busy?null:_pick,icon:const Icon(Icons.add_circle_outline,color:JagxColors.fg)),IconButton(tooltip:'AI mode',onPressed:_busy?null:_mode,icon:const Icon(Icons.tune,color:JagxColors.muted)),if(_locationContext!=null)IconButton(tooltip:'Open live map',onPressed:_location,icon:const Icon(Icons.location_on_outlined,color:JagxColors.accent)),Expanded(child:TextField(controller:_input,minLines:1,maxLines:7,decoration:const InputDecoration(hintText:'Message',border:InputBorder.none),onSubmitted:(_)=>_send())),IconButton.filled(onPressed:_busy?null:_send,style:IconButton.styleFrom(backgroundColor:JagxColors.fg,foregroundColor:JagxColors.bg),icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.arrow_upward))]),if(_locationContext==null)Align(alignment:Alignment.centerLeft,child(TextButton.icon(onPressed:_busy?null:_location,icon:const Icon(Icons.my_location,size:16),label:const Text('Use live location'))))])));
}
