import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/grades.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../books/book_studio_screen.dart';
import '../chat/chat_screen.dart';
import '../code/code_lab_screen.dart';
import '../images/image_studio_screen.dart';
import '../developer/developer_keys_screen.dart';

class HomeShell extends StatefulWidget{const HomeShell({super.key});@override State<HomeShell> createState()=>_HomeShellState();}
class _HomeShellState extends State<HomeShell>{
 int tab=0;Grade grade=grades.first;bool web=true;
 @override Widget build(BuildContext c){final auth=c.watch<AuthService>();final pages=[ChatScreen(grade:grade,webEnabled:web),const CodeLabScreen(),const BookStudioScreen(),const ImageStudioScreen()];
 return Scaffold(appBar:AppBar(titleSpacing:16,title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('JagX AI',style:TextStyle(fontWeight:FontWeight.w700,fontSize:18,color:JagxColors.fg)),Text('v'+AppConfig.version+' · '+grade.label,style:const TextStyle(fontSize:10,letterSpacing:1.6,color:JagxColors.subtle,fontFamily:'monospace'))]),actions:[
 if(tab==0) ...[IconButton(tooltip:web?'Live web on':'Live web off',onPressed:()=>setState(()=>web=!web),icon:Icon(Icons.public,color:web?JagxColors.accent:JagxColors.subtle)),PopupMenuButton<String>(color:JagxColors.surface,onSelected:(id)=>setState(()=>grade=gradeById(id)),itemBuilder:(x)=>[for(final g in grades)PopupMenuItem(value:g.id,child:Text(g.label+' — '+g.blurb))],child:const Icon(Icons.tune,color:JagxColors.muted))],
 PopupMenuButton<String>(color:JagxColors.surface,onSelected:(v)async{if(v=='developer'){await Navigator.of(c).push(MaterialPageRoute(builder:(_)=>const DeveloperKeysScreen()));}else if(auth.currentUser==null){await Navigator.of(c).push(MaterialPageRoute(builder:(_)=>const LoginScreen()));}else{await auth.signOut();}if(mounted)setState((){});},itemBuilder:(_)=>const[PopupMenuItem(value:'developer',child:Text('Developer API')),PopupMenuItem(value:'account',child:Text('Account'))],child:const Icon(Icons.more_horiz,color:JagxColors.muted))],
 body:IndexedStack(index:tab,children:pages),bottomNavigationBar:NavigationBar(backgroundColor:JagxColors.surface,indicatorColor:JagxColors.elevated,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'Chat'),NavigationDestination(icon:Icon(Icons.terminal),label:'Code'),NavigationDestination(icon:Icon(Icons.menu_book_outlined),label:'Books'),NavigationDestination(icon:Icon(Icons.image_outlined),label:'Images')]));
 }
}