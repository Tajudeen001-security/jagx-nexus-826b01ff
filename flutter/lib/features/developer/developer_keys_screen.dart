import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/jagx_theme.dart';

class DeveloperKeysScreen extends StatefulWidget{const DeveloperKeysScreen({super.key});@override State<DeveloperKeysScreen> createState()=>_DeveloperKeysScreenState();}
class _DeveloperKeysScreenState extends State<DeveloperKeysScreen>{
 static const storage=FlutterSecureStorage();List<Map<String,String>> keys=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{final raw=await storage.read(key:'jagx_developer_keys');if(raw!=null){keys=(jsonDecode(raw) as List).map((e)=>Map<String,String>.from(e as Map)).toList();}if(mounted)setState(()=>loading=false);}
 String makeKey(){const a='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';final r=Random.secure();return 'jagx-'+List.generate(40,(_)=>a[r.nextInt(a.length)]).join();}
 Future<void> create(String tier)async{final k=makeKey();setState(()=>keys.insert(0,{'key':k,'tier':tier}));await storage.write(key:'jagx_developer_keys',value:jsonEncode(keys));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Developer token created securely on this device.')));}
 Future<void> copy(String k)async{await Clipboard.setData(ClipboardData(text:k));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('API key copied.')));}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Developer API')),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
 const Text('Build with JagX',style:TextStyle(fontSize:28,fontWeight:FontWeight.w700,color:JagxColors.fg)),const SizedBox(height:8),const Text('Create project tokens and choose the capability grade.',style:TextStyle(color:JagxColors.muted)),const SizedBox(height:20),
 Card(color:JagxColors.surface,child:Padding(padding:const EdgeInsets.all(18),child:Wrap(spacing:8,runSpacing:8,children:[for(final t in ['free','premium','premium_plus','master'])FilledButton.tonal(onPressed:()=>create(t),child:Text(t.replaceAll('_',' ').toUpperCase()))]))),
 const SizedBox(height:20),if(keys.isEmpty)const Text('No developer tokens yet.',style:TextStyle(color:JagxColors.subtle)),...keys.map((k)=>Card(color:JagxColors.surface,child:ListTile(title:Text(k['key']!,style:const TextStyle(fontFamily:'monospace',fontSize:12)),subtitle:Text(k['tier']!.toUpperCase(),style:const TextStyle(color:JagxColors.accent,fontSize:10,letterSpacing:1.4)),trailing:IconButton(icon:const Icon(Icons.copy),onPressed:()=>copy(k['key']!))))),
 const SizedBox(height:20),const Text('Security note: the documented JagX /create-key endpoint requires an admin secret. These local project tokens therefore do not pretend to be server-issued keys. The production backend should expose an authenticated user provisioning endpoint before these tokens are accepted by the hosted API.',style:TextStyle(color:JagxColors.subtle,fontSize:12,height:1.45))
 ]));
}
