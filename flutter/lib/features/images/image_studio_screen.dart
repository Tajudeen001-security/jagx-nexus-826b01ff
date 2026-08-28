import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ai_service.dart';
import '../../theme/jagx_theme.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';

class ImageStudioScreen extends StatefulWidget {
  const ImageStudioScreen({super.key});
  @override
  State<ImageStudioScreen> createState() => _ImageStudioScreenState();
}

class _ImageStudioScreenState extends State<ImageStudioScreen> {
  final _prompt = TextEditingController();
  bool _busy = false;
  String? _url;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _url = null;
    });
    try {
      final url = await AiService().generateImageUrl(_prompt.text.trim());
      setState(() => _url = url);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Image Studio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: JagxColors.fg,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Free image generation (Pollinations). No API key required.',
          style: TextStyle(color: JagxColors.muted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _prompt,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Prompt'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy || _prompt.text.trim().isEmpty ? null : _go,
          style: FilledButton.styleFrom(
            backgroundColor: JagxColors.fg,
            foregroundColor: JagxColors.bg,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(_busy ? 'Generating…' : 'Generate'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: JagxColors.danger)),
          ),
        if (_url != null) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              _url!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => const Text(
                'Could not load image. Try again.',
                style: TextStyle(color: JagxColors.danger),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
