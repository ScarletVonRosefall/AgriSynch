import 'package:flutter/material.dart';
import 'signup.dart';
import 'login.dart';
import 'recover.dart';
import 'verify.dart';
import 'home.dart';

void
main() {
  runApp(
    const AgriflowApp(),
  );
}

class AgriflowApp
    extends
        StatelessWidget {
  const AgriflowApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'Agriflow',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(
          0xFFEFFFF0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/signup',
      routes: {
        '/signup':
            (
              context,
            ) => const SignUpPage(),
        '/login':
            (
              context,
            ) => const LoginPage(),
        '/recover':
            (
              context,
            ) => const RecoverPage(),
        '/verify':
            (
              context,
            ) => const VerifyPage(),
        '/home':
            (
              context,
            ) => const HomePage(),
      },
    );
  }
}
