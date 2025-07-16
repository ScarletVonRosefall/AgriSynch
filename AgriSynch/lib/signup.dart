import 'package:flutter/material.dart';

class SignUpPage
    extends
        StatefulWidget {
  const SignUpPage({
    super.key,
  });

  @override
  State<
    SignUpPage
  >
  createState() => _SignUpPageState();
}

class _SignUpPageState
    extends
        State<
          SignUpPage
        > {
  bool _isDarkMode = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final formKey =
      GlobalKey<
        FormState
      >();

  bool isValidEmail(
    String email,
  ) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(
      email,
    );
  }

  bool isValidPassword(
    String password,
  ) {
    final passRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d).{6,}$',
    );
    return passRegex.hasMatch(
      password,
    );
  }

  void showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = _isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(
              0xFF388E3C,
            ),
            scaffoldBackgroundColor: const Color(
              0xFF232D23,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF2E473B,
              ),
              foregroundColor: Colors.white,
              elevation: 2,
              iconTheme: IconThemeData(
                color: Color(
                  0xFFB2FF59,
                ),
              ),
              titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(
                  0xFFB2FF59,
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(
                0xFF2E473B,
              ),
              hintStyle: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    20,
                  ),
                ),
                borderSide: BorderSide.none,
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(
                0xFF388E3C,
              ),
              secondary: Color(
                0xFFB2FF59,
              ),
              background: Color(
                0xFF232D23,
              ),
              surface: Color(
                0xFF2E473B,
              ),
              onPrimary: Colors.white,
              onSecondary: Color(
                0xFF232D23,
              ),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(
              0xFF388E3C,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF388E3C,
              ),
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(
                0xFFD9F2E6,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    20,
                  ),
                ),
                borderSide: BorderSide.none,
              ),
            ),
          );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Sign Up',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
              ),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                setState(
                  () {
                    _isDarkMode = !_isDarkMode;
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Welcome to",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          "AgriSynch",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            color: Color(
                              0xFF1DBF73,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Image.asset(
                          'assets/logo.png',
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF00A862,
                      ),
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                    ),
                    padding: const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _inputField(
                          "Name",
                          nameController,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        _inputField(
                          "Email",
                          emailController,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        _inputField(
                          "Password",
                          passController,
                          obscure: true,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              final email = emailController.text.trim();
                              final pass = passController.text;
                              if (!isValidEmail(
                                email,
                              )) {
                                showError(
                                  "Please enter a valid email address.",
                                );
                                return;
                              }
                              if (!isValidPassword(
                                pass,
                              )) {
                                showError(
                                  "Password must be at least 6 characters and include a letter and a number.",
                                );
                                return;
                              }
                              Navigator.pushNamed(
                                context,
                                '/verify',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  20,
                                ),
                              ),
                            ),
                            child: const Text(
                              "Next",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/login',
                            ),
                            child: const Text(
                              "Already have an account? Sign In",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(
          context,
        ).inputDecorationTheme.fillColor,
        hintStyle:
            Theme.of(
              context,
            ).inputDecorationTheme.hintStyle ??
            const TextStyle(
              fontFamily: 'Poppins',
            ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            20,
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
