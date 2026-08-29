import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  runApp(const JagxApp());
}

class JagxApp extends StatelessWidget {
  const JagxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JagX AI',
      debugShowCheckedModeBanner: false,
      theme: JagxTheme.dark(),
      home: const HomeShell(),
    );
  }
}
