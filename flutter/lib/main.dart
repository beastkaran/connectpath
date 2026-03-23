import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/app_state.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PPNApp(),
    ),
  );
}

class PPNApp extends StatelessWidget {
  const PPNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectPath',
      debugShowCheckedModeBanner: false,
      theme: PPNTheme.theme,
      initialRoute: '/',
      routes: {
        '/':        (_) => const SplashScreen(),
        '/login':   (_) => const LoginScreen(),
        '/register':(_) => const RegisterScreen(),
        '/home':    (_) => const HomeScreen(),
      },
    );
  }
}
