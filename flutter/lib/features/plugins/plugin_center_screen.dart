import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/jagx_theme.dart';

class PluginCenterScreen extends StatefulWidget{const PluginCenterScreen({super.key});@override State<PluginCenterScreen> createState()=>_PluginCenterScreenState();}
class _PluginCenterScreenState extends State<PluginCenterScreen>{
  final _plugins=const[
    ('GitHub','Repositories, issues, pull requests and code',Icons.code),('Supabase','Database, auth, storage and edge functions',Icons.storage),('Email','Draft, send and organize email',Icons.email_outlined),('Webhooks / APIs','Connect REST APIs and automations',Icons.link),('Google Drive','Read and create files',Icons.cloud_outlined),
    ('Google Calendar','Events, schedules and reminders',Icons.calendar_month),('Google Maps','Maps, places, directions and location context',Icons.map_outlined),('Slack','Messages, channels and team workflows',Icons.forum_outlined),('Notion','Pages, notes, databases and knowledge',Icons.menu_book_outlined),('Dropbox','Cloud files and folders',Icons.folder_open),('OneDrive','Microsoft cloud files',Icons.cloud_queue),('Trello','Boards, cards and project workflows',Icons.view_kanban_outlined),('Jira','Issues, sprints and engineering work',Icons.bug_report_outlined),('Linear','Product issues and roadmaps',Icons.timeline),('Figma','Design files and product context',Icons.design_services_outlined),('Discord','Communities and channels',Icons.groups_outlined),('YouTube','Videos, channels and transcripts',Icons.play_circle_outline),
  ];
  final Set<String> _connected={};
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();if(mounted)setState(()=>_connected.addAll(p.getStringList('jagx_plugins')??const[]));}
  Future<void> _toggle(String n)async{final p=await SharedPreferences.getInstance();setState((){_connected.contains(n)?_connected.remove(n):_connected.add(n);});await p.setStringList('jagx_plugins',_connected.toList());}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Plugins')),body:ListView(padding:const EdgeInsets.fromLTRB(20,12,20,32),children:[const Text('Connect JagX to your tools',style:TextStyle(fontSize:28,fontWeight:FontWeight.w700,color:JagxColors.fg)),const SizedBox(height:8),const Text('These connectors are exposed as capabilities for the AI. Credentials stay outside the chat.',style:TextStyle(color:JagxColors.muted,height:1.45)),const SizedBox(height:20),..._plugins.map((p)=>Card(color:JagxColors.surface,margin:const EdgeInsets.only(bottom:10),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:6),leading:CircleAvatar(backgroundColor:JagxColors.elevated,child:Icon(p.$3,color:JagxColors.fg)),title:Text(p.$1,style:const TextStyle(color:JagxColors.fg,fontWeight:FontWeight.w600)),subtitle:Text(p.$2,style:const TextStyle(color:JagxColors.muted)),trailing:OutlinedButton(onPressed:()=>_toggle(p.$1),child:Text(_connected.contains(p.$1)?'Connected':'Connect')))))]));
}
