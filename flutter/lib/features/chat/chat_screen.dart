import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai_service.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'chat_models.dart';

class _Attachment{final String name,type;const _Attachment(this.name,this.type);}
class ChatScreen extends StatefulWidget{final Grade grade;final bool webEnabled;const ChatScreen({super.key,required this.grade,required this.webEnabled});@override State<ChatScreen> createState()=>_ChatScreenState();}
class _ChatScreenState extends State<ChatScreen>{
 final input=TextEditingController(),scroll=ScrollController(),_id=const Uuid();final messages=<ChatMessage>[],attachments=<_Attachment>[];bool busy=false;String live='Thinking';int liveIdx=0;final steps=const['Parsing intent','Searching the live web','Reading sources','Thinking','Writing'];
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 Future<void> pickFiles()async{final r=await FilePicker.platform.pickFiles(allowMultiple:true);if(r==null||!mounted)return;setState((){for(final f in r.files){if(attachments.length>=8)break;attachments.add(_Attachment(f.name,mime(f.extension??'')));}});}
 String mime(String e){const m={'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif','pdf':'application/pdf','txt':'text/plain','md':'text/markdown','json':'application/json','dart':'text/plain','kt':'text/plain','java':'text/plain','ts':'text/plain','tsx':'text/plain','js':'text/plain','py':'text/plain','go':'text/plain','rs':'text/plain'};return m[e.toLowerCase()]??'application/octet-stream';}
 Future<void> send([String? preset])async{
  final text=(preset??input.text).trim();if((text.isEmpty&&attachments.isEmpty)||busy)return;
  if(context.read<AuthService>().currentUser==null){final ok=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>const LoginScreen()));if(ok!=true||!mounted)return;}
  final a=List<_Attachment>.from(attachments);final prompt=(text.isEmpty?'Please inspect the attached files.':text)+(a.isEmpty?'':'\n\nATTACHMENTS:\n'+a.map((x)=>'- '+x.name+' ('+x.type+')').join('\n'));
  setState((){busy=true;liveIdx=0;live=steps[0];input.clear();attachments.clear();messages.add(ChatMessage(id:_id.v4(),role:'user',content:prompt));messages.add(ChatMessage(id:_id.v4(),role:'assistant',content:'',pending:true));});
  final pending=messages.last.id;final ticker=Stream.periodic(const Duration(milliseconds:900)).listen((_){if(!mounted||!busy)return;setState((){liveIdx=(liveIdx+1)%steps.length;live=steps[liveIdx];});});
  final history=messages.where((m)=>!m.pending&&m.content.isNotEmpty).take(messages.length-2).map((m)=>ChatTurn(role:m.role,content:m.content)).toList();
  final result=await AiService(onStep:(s){if(mounted)setState(()=>live=s.label);}).chat(message:prompt,history:history,grade:widget.grade,web:widget.webEnabled);
  await ticker.cancel();if(!mounted)return;
  setState((){busy=false;final i=messages.indexWhere((m)=>m.id==pending);if(i>=0)messages[i]=ChatMessage(id:pending,role:'assistant',content:result.ok?result.text:(result.error??'Failed'),steps:result.steps,sources:result.sources,durationMs:result.durationMs,model:result.model);});
 }
 @override Widget build(BuildContext c)=>Column(children:[Expanded(child:messages.isEmpty?empty():list()),composer()]);
 Widget empty()=>ListView(padding:const EdgeInsets.fromLTRB(20,48,20,20),children:[const Text('Ask JagX anything',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.w600,color:JagxColors.fg)),const SizedBox(height:10),const Text('Live web research • coding terminal • books • image studio',textAlign:TextAlign.center,style:TextStyle(color:JagxColors.muted)),const SizedBox(height:28),...['Design a fault-tolerant job queue','Write a TypeScript rate limiter','What shipped in AI this week?'].map((x)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:JagxColors.surface,borderRadius:BorderRadius.circular(16),child:InkWell(onTap:()=>send(x),child:Padding(padding:const EdgeInsets.all(14),child:Text(x,style:const TextStyle(color:JagxColors.muted)))))))]);
 Widget list()=>ListView.builder(controller:scroll,padding:const EdgeInsets.all(16),itemCount:messages.length,itemBuilder:(c,i){final m=messages[i];if(m.role=='user')return Align(alignment:Alignment.centerRight,child:Container(margin:const EdgeInsets.only(bottom:16,left:40),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:JagxColors.elevated,borderRadius:BorderRadius.circular(18)),child:Text(m.content,style:const TextStyle(color:JagxColors.fg))));if(m.pending)return Padding(padding:const EdgeInsets.only(bottom:20),child:Text(live.toUpperCase(),style:const TextStyle(color:JagxColors.accent,fontSize:11,letterSpacing:1.6,fontFamily:'monospace')));return Padding(padding:const EdgeInsets.only(bottom:24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[...m.steps.map((s)=>Text('· '+s.label,style:const TextStyle(color:JagxColors.subtle,fontSize:11,fontFamily:'monospace'))),MarkdownBody(data:m.content,styleSheet:MarkdownStyleSheet(p:const TextStyle(color:JagxColors.fg,height:1.55)))]));};
 Widget composer()=>SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Column(children:[if(attachments.isNotEmpty)SizedBox(height:52,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:attachments.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i)=>InputChip(label:SizedBox(width:130,child:Text(attachments[i].name,overflow:TextOverflow.ellipsis)),avatar:Icon(attachments[i].type.startsWith('image/')?Icons.image_outlined:Icons.insert_drive_file_outlined),onDeleted:busy?null:()=>setState(()=>attachments.removeAt(i)))),Row(children:[IconButton(tooltip:'Attach files, images, PDFs and code',onPressed:busy?null:pickFiles,icon:const Icon(Icons.add_circle_outline,size:28,color:JagxColors.fg)),Expanded(child:TextField(controller:input,minLines:1,maxLines:6,decoration:const InputDecoration(hintText:'Message JagX AI',border:OutlineInputBorder(borderSide:BorderSide.none)),onSubmitted:(_)=>send())),IconButton.filled(onPressed:busy?null:()=>send(),style:IconButton.styleFrom(backgroundColor:JagxColors.fg,foregroundColor:JagxColors.bg),icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.arrow_upward))])])));}
}