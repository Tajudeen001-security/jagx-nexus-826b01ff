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

class _Attachment{final String name,type;const _Attachment({required this.name,required this.type});}
class ChatScreen extends StatefulWidget{
 final Grade grade;final bool webEnabled;
 const ChatScreen({super.key,required this.grade,required this.webEnabled});
 @override State<ChatScreen> createState()=>_ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen>{
 final input=TextEditingController(),scroll=ScrollController(),_uuid=const Uuid();
 final messages=<ChatMessage>[],attachments=<_Attachment>[];
 bool busy=false;String live='Thinking';int liveIdx=0;
 final liveSteps=const['Parsing intent','Searching the live web','Reading sources','Thinking','Writing'];
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 Future<void> pickFiles()async{
  final result=await FilePicker.platform.pickFiles(allowMultiple:true);
  if(result==null||!mounted)return;
  setState((){for(final file in result.files){if(attachments.length>=8)break;attachments.add(_Attachment(name:file.name,type:_mime(file.extension??'')));}});
 }
 String _mime(String ext){const map={'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif','pdf':'application/pdf','txt':'text/plain','md':'text/markdown','json':'application/json','dart':'text/plain','kt':'text/plain','java':'text/plain','ts':'text/plain','tsx':'text/plain','js':'text/plain','py':'text/plain','go':'text/plain','rs':'text/plain'};return map[ext.toLowerCase()]??'application/octet-stream';}
 Future<void> send([String? preset])async{
  final text=(preset??input.text).trim();if((text.isEmpty&&attachments.isEmpty)||busy)return;
  if(context.read<AuthService>().currentUser==null){
   final ok=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>const LoginScreen()));
   if(ok!=true||!mounted)return;
  }
  final attached=List<_Attachment>.from(attachments);
  final attachmentText=attached.isEmpty?'':'\n\nATTACHMENTS:\n'+attached.map((a)=>'- '+a.name+' ('+a.type+')').join('\n');
  final prompt=(text.isEmpty?'Please inspect the attached files.':text)+attachmentText;
  setState((){busy=true;liveIdx=0;live=liveSteps[0];input.clear();attachments.clear();messages.add(ChatMessage(id:_uuid.v4(),role:'user',content:prompt));messages.add(ChatMessage(id:_uuid.v4(),role:'assistant',content:'',pending:true));});
  final pendingId=messages.last.id;
  final ticker=Stream.periodic(const Duration(milliseconds:900)).listen((_){if(!mounted||!busy)return;setState((){liveIdx=(liveIdx+1)%liveSteps.length;live=liveSteps[liveIdx];});});
  final history=messages.where((m)=>!m.pending&&m.content.isNotEmpty).take(messages.length-2).map((m)=>ChatTurn(role:m.role,content:m.content)).toList();
  final result=await AiService(onStep:(step){if(mounted)setState(()=>live=step.label);}).chat(message:prompt,history:history,grade:widget.grade,web:widget.webEnabled);
  await ticker.cancel();if(!mounted)return;
  setState((){busy=false;final i=messages.indexWhere((m)=>m.id==pendingId);if(i>=0)messages[i]=ChatMessage(id:pendingId,role:'assistant',content:result.ok?result.text:(result.error??'Failed'),steps:result.steps,sources:result.sources,durationMs:result.durationMs,model:result.model);});
 }
 @override Widget build(BuildContext context)=>Column(children:[Expanded(child:messages.isEmpty?_empty():_list()),_composer()]);
 Widget _empty()=>ListView(padding:const EdgeInsets.fromLTRB(20,48,20,20),children:[
  const Text('Ask JagX anything',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.w600,color:JagxColors.fg)),
  const SizedBox(height:10),const Text('Live web research • coding terminal • books • image studio',textAlign:TextAlign.center,style:TextStyle(color:JagxColors.muted)),
  const SizedBox(height:28),
  ...['Design a fault-tolerant job queue','Write a TypeScript rate limiter','What shipped in AI this week?'].map((hint)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:JagxColors.surface,borderRadius:BorderRadius.circular(16),child:InkWell(onTap:()=>send(hint),child:Padding(padding:const EdgeInsets.all(14),child:Text(hint,style:const TextStyle(color:JagxColors.muted)))))))
 ]);
 Widget _list()=>ListView.builder(
  controller:scroll,padding:const EdgeInsets.all(16),itemCount:messages.length,
  itemBuilder:(context,index){
   final message=messages[index];
   if(message.role=='user')return Align(alignment:Alignment.centerRight,child:Container(margin:const EdgeInsets.only(bottom:16,left:40),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:JagxColors.elevated,borderRadius:BorderRadius.circular(18)),child:Text(message.content,style:const TextStyle(color:JagxColors.fg))));
   if(message.pending)return Padding(padding:const EdgeInsets.only(bottom:20),child:Text(live.toUpperCase(),style:const TextStyle(color:JagxColors.accent,fontSize:11,letterSpacing:1.6,fontFamily:'monospace')));
   return Padding(padding:const EdgeInsets.only(bottom:24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ...message.steps.map((step)=>Text('· '+step.label,style:const TextStyle(color:JagxColors.subtle,fontSize:11,fontFamily:'monospace'))),
    MarkdownBody(data:message.content,styleSheet:MarkdownStyleSheet(p:const TextStyle(color:JagxColors.fg,height:1.55))),
   ]));
  },
 );
 Widget _composer()=>SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Column(children:[
  if(attachments.isNotEmpty)SizedBox(height:52,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:attachments.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){
   final file=attachments[i];
   return InputChip(label:SizedBox(width:130,child:Text(file.name,overflow:TextOverflow.ellipsis)),avatar:Icon(file.type.startsWith('image/')?Icons.image_outlined:Icons.insert_drive_file_outlined,size:18,color:JagxColors.accent),onDeleted:busy?null:()=>setState(()=>attachments.removeAt(i)));
  })),
  Row(children:[
   IconButton(tooltip:'Attach files, images, PDFs and code',onPressed:busy?null:pickFiles,icon:const Icon(Icons.add_circle_outline,size:28,color:JagxColors.fg)),
   Expanded(child:TextField(controller:input,minLines:1,maxLines:6,decoration:const InputDecoration(hintText:'Message JagX AI',border:OutlineInputBorder(borderSide:BorderSide.none)),onSubmitted:(_)=>send())),
   const SizedBox(width:8),
   IconButton.filled(onPressed:busy?null:()=>send(),style:IconButton.styleFrom(backgroundColor:JagxColors.fg,foregroundColor:JagxColors.bg),icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.arrow_upward)),
  ])
 ]));
}
