import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class AuthUser {
  final String id;
  final String email;
  final String? name;
  const AuthUser({required this.id,required this.email,this.name});
  factory AuthUser.fromJson(Map<String,dynamic> j)=>AuthUser(id:j['id'] as String? ?? '',email:j['email'] as String? ?? '',name:j['name'] as String?);
}

class AuthService extends ChangeNotifier {
  static const _storage=FlutterSecureStorage();
  static const _tokenKey='jagx_better_auth_token';
  AuthUser? currentUser;
  String? sessionToken;

  Future<void> restore() async { sessionToken=await _storage.read(key:_tokenKey); if(sessionToken!=null) await refresh(); notifyListeners(); }

  Map<String,String> get _headers { final h=<String,String>{'Content-Type':'application/json'}; if(sessionToken!=null) h['Authorization']='Bearer $sessionToken'; return h; }

  Future<bool> refresh() async {
    try {
      final r=await http.get(Uri.parse('${AppConfig.authBaseUrl}/api/auth/get-session'),headers:_headers);
      if(r.statusCode==200){
        if(r.body.trim()=='null'){await signOut(localOnly:true);return false;}
        final d=jsonDecode(r.body) as Map<String,dynamic>; final u=d['user'] as Map<String,dynamic>?; final s=d['session'] as Map<String,dynamic>?;
        if(u!=null) currentUser=AuthUser.fromJson(u);
        final t=s?['token'] as String?; if(t!=null){sessionToken=t;await _storage.write(key:_tokenKey,value:t);}
        notifyListeners();return currentUser!=null;
      }
    } catch (_) {}
    return currentUser!=null;
  }

  Future<AuthUser> signInEmail({required String email,required String password}) async => _complete(await http.post(Uri.parse('${AppConfig.authBaseUrl}/api/auth/sign-in/email'),headers:_headers,body:jsonEncode({'email':email,'password':password})));
  Future<AuthUser> signUpEmail({required String email,required String password,required String name}) async => _complete(await http.post(Uri.parse('${AppConfig.authBaseUrl}/api/auth/sign-up/email'),headers:_headers,body:jsonEncode({'email':email,'password':password,'name':name})));
  Future<AuthUser> signInWithGoogleProfile({required String email,required String name,String? idToken}) async => throw Exception('Use Better Auth Google OAuth after the Google provider and mobile callback are configured.');

  Future<AuthUser> _complete(http.Response r) async {
    if(r.statusCode<200||r.statusCode>=300) throw Exception(_error(r));
    final d=jsonDecode(r.body) as Map<String,dynamic>; final u=d['user'] as Map<String,dynamic>?;
    if(u==null) throw Exception('Better Auth returned no user.');
    currentUser=AuthUser.fromJson(u); final s=d['session'] as Map<String,dynamic>?; final t=s?['token'] as String? ?? d['token'] as String?;
    if(t!=null){sessionToken=t;await _storage.write(key:_tokenKey,value:t);} notifyListeners();return currentUser!;
  }

  String _error(http.Response r){try{final d=jsonDecode(r.body) as Map<String,dynamic>;return d['message'] as String? ?? d['error'] as String? ?? 'Authentication failed (${r.statusCode}).';}catch(_){return 'Authentication failed (${r.statusCode}).';}}
  Future<void> signOut({bool localOnly=false}) async {if(!localOnly){try{await http.post(Uri.parse('${AppConfig.authBaseUrl}/api/auth/sign-out'),headers:_headers);}catch(_){}} currentUser=null;sessionToken=null;await _storage.delete(key:_tokenKey);notifyListeners();}
}
