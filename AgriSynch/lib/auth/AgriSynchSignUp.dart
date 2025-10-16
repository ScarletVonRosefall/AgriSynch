import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class AgriSynchSignUpPage
    extends
        StatefulWidget {
  const AgriSynchSignUpPage({
    super.key,
  });

  @override
  State<
    AgriSynchSignUpPage
  >
  createState() => _SignUpPageState();
}

class _SignUpPageState
    extends
        State<
          AgriSynchSignUpPage
        > with TickerProviderStateMixin {
  bool _isDarkMode = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final formKey =
      GlobalKey<
        FormState
      >();
  
  String _selectedAccountType = 'Farmer'; // Default to Farmer
  bool _isPasswordVisible = false; // Track password visibility

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

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
              surface: Color(
                0xFF232D23,
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
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
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: value,
                                    child: Image.asset(
                                      'assets/AgriSynchLogoNB2.png',
                                      height: 100,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A862),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
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
                        _passwordField(),
                        const SizedBox(
                          height: 16,
                        ),
                        const Text(
                          "Which type of account?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAccountType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF00A862),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Farmer',
                                  child: Text(
                                    'Farmer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Buyer',
                                  child: Text(
                                    'Buyer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccountType = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final email = emailController.text.trim();
                              final pass = passController.text;

                              if (name.isEmpty) {
                                showError("Please enter your name.");
                                return;
                              }
                              if (!isValidEmail(email)) {
                                showError("Please enter a valid email address.");
                                return;
                              }
                              if (!isValidPassword(pass)) {
                                showError("Password must be at least 6 characters and include a letter and a number.");
                                return;
                              }

                              // Save user data with selected account type
                              await storage.write(key: 'name', value: name.trim());
                              await storage.write(key: 'user_email', value: email.trim());
                              await storage.write(key: 'account_type', value: _selectedAccountType);
                              await storage.write(key: 'user_password', value: pass.trim());
                              
                              // Navigate to login page
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
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
                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: "Password",
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
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
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
