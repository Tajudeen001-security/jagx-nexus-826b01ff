import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_service.dart';
import 'features/home/home_shell.dart';
import 'theme/jagx_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: JagxColors.bg,
    ),
  );
  final auth = AuthService();
  await auth.restore();
  runApp(JagxApp(auth: auth));
}

class JagxApp extends StatelessWidget {
  final AuthService auth;

  const JagxApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: MaterialApp(
        title: 'JagX AI',
        debugShowCheckedModeBanner: false,
        theme: JagxTheme.dark(),
        home: const HomeShell(),
      ),
    );
  }
}
