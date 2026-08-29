import 'package:flutter/material.dart';
import '../../core/config.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../chat/nexus_chat_screen.dart';
import '../developer/developer_keys_screen.dart';
import '../plugins/plugin_center_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState()=>_HomeShellState();
}

class _HomeShellState extends State<HomeShell>{
  Grade _grade=grades.first;
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      titleSpacing:20,
      title:const Text('JagX AI',style:TextStyle(fontWeight:FontWeight.w700,fontSize:20,color:JagxColors.fg)),
      actions:[
        IconButton(tooltip:'Plugins',onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const PluginCenterScreen())),icon:const Icon(Icons.extension_outlined,color:JagxColors.muted)),
        PopupMenuButton<String>(color:JagxColors.surface,onSelected:(v)async{if(v=='developer')await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const DeveloperKeysScreen()));},itemBuilder:(_)=>const[PopupMenuItem(value:'developer',child:Text('Developer API'))],child:const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Icon(Icons.more_horiz,color:JagxColors.muted))),
      ],
    ),
    body:NexusChatScreen(grade:_grade,onGradeChanged:(g)=>setState(()=>_grade=g)),
  );
}
