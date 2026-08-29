import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../theme/jagx_theme.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    final auth = context.read<AuthService>();
    try {
      if (_signUp) {
        await auth.signUpEmail(email: _email.text.trim(), password: _password.text, name: _name.text.trim().isEmpty ? 'JagX user' : _name.text.trim());
      } else {
        await auth.signInEmail(email: _email.text.trim(), password: _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() { _busy = true; _error = null; });
    try {
      // Google Sign-In is optional; email auth remains the default path.
      final account = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (account == null) { setState(() => _busy = false); return; }
      final ga = await account.authentication;
      await context.read<AuthService>().signInWithGoogleProfile(email: account.email, name: account.displayName ?? account.email, idToken: ga.idToken);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'JagX ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: JagxColors.fg)),
                  TextSpan(text: 'AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: JagxColors.accent)),
                ])),
                const Text('v1.1.2 · sign in', style: TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 2.2, color: JagxColors.subtle)),
                const SizedBox(height: 32),
                Text(_signUp ? 'Create an account' : 'Welcome back', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: JagxColors.fg)),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: _busy ? null : _google, child: const Text('Continue with Google')),
                const SizedBox(height: 16),
                if (_signUp) TextField(controller: _name, decoration: const InputDecoration(hintText: 'Name')),
                if (_signUp) const SizedBox(height: 10),
                TextField(controller: _email, decoration: const InputDecoration(hintText: 'Email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                TextField(controller: _password, decoration: const InputDecoration(hintText: 'Password'), obscureText: true),
                if (_error != null) Text(_error!, style: const TextStyle(color: JagxColors.danger)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: JagxColors.fg, foregroundColor: JagxColors.bg, minimumSize: const Size.fromHeight(48)),
                  child: Text(_busy ? 'Working…' : (_signUp ? 'Create account' : 'Sign in')),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                  child: Text(_signUp ? 'Have an account? Sign in' : 'Need an account? Sign up', style: const TextStyle(color: JagxColors.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
