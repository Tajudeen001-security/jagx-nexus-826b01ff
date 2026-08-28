import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config.dart';

class AuthUser {
  final String id;
  final String email;
  final String? name;
  const AuthUser({required this.id, required this.email, this.name});
  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String? ?? '',
        email: j['email'] as String? ?? '',
        name: j['name'] as String?,
      );
}

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'jagx_session_token';
  static const _userKey = 'jagx_user_json';
  AuthUser? currentUser;
  String? sessionToken;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    sessionToken = prefs.getString(_tokenKey);
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      try {
        currentUser = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionToken != null) {
      await prefs.setString(_tokenKey, sessionToken!);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (currentUser != null) {
      await prefs.setString(_userKey, jsonEncode({
        'id': currentUser!.id,
        'email': currentUser!.email,
        'name': currentUser!.name,
      }));
    } else {
      await prefs.remove(_userKey);
    }
    notifyListeners();
  }

  Future<AuthUser> _localSession({required String email, required String name}) async {
    final user = AuthUser(id: 'local_${email.hashCode.abs()}', email: email, name: name);
    currentUser = user;
    sessionToken = 'local_${DateTime.now().millisecondsSinceEpoch}';
    await _persist();
    return user;
  }

  Future<AuthUser> signInEmail({required String email, required String password}) async {
    try {
      final uri = Uri.parse('${AppConfig.authBaseUrl}/api/auth/sign-in/email');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final userMap = (data['user'] as Map<String, dynamic>?) ?? data;
        currentUser = AuthUser.fromJson(userMap);
        sessionToken = data['token'] as String? ?? 'session';
        await _persist();
        return currentUser!;
      }
    } catch (_) {}
    return _localSession(email: email, name: email.split('@').first);
  }

  Future<AuthUser> signUpEmail({required String email, required String password, required String name}) async {
    try {
      final uri = Uri.parse('${AppConfig.authBaseUrl}/api/auth/sign-up/email');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'name': name}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return signInEmail(email: email, password: password);
      }
    } catch (_) {}
    return _localSession(email: email, name: name);
  }

  Future<AuthUser> signInWithGoogleProfile({required String email, required String name, String? idToken}) async {
    return _localSession(email: email, name: name);
  }

  Future<void> signOut() async {
    currentUser = null;
    sessionToken = null;
    await _persist();
  }
}
