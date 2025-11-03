import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/error_handler.dart';

class AgriSynchLoginPage extends StatefulWidget {
  const AgriSynchLoginPage({super.key});

  @override
  State<AgriSynchLoginPage> createState() => _AgriSynchLoginPageState();
}

class _AgriSynchLoginPageState extends State<AgriSynchLoginPage>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final ValueNotifier<bool> isLoading = ValueNotifier(false);
    final ValueNotifier<bool> showPassword = ValueNotifier(false);

    return Scaffold(
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    "Log in to continue",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    "AgriSynch",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 28,
                                      color: Color(0xFF1DBF73),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
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
                            const SizedBox(height: 16),
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
                                      "Log in",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _inputField(
                                      "Email",
                                      emailController,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: showPassword,
                                      builder: (context, value, child) {
                                        return _inputField(
                                          "Password",
                                          passController,
                                          obscure: !value,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              value
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () =>
                                                showPassword.value = !value,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: ValueListenableBuilder<bool>(
                                        valueListenable: isLoading,
                                        builder: (context, loading, child) {
                                          return ElevatedButton(
                                            onPressed: loading
                                                ? null
                                                : () async {
                                                    final email = emailController.text.trim();
                                                    final pass = passController.text.trim();

                                                    if (email.isEmpty || pass.isEmpty) {
                                                      showError("Please enter both email and password.");
                                                      return;
                                                    }

                                                    if (!mounted) return;
                                                    isLoading.value = true;

                                                    try {
                                                      // Add timeout for Firebase operations
                                                      final loginFuture = FirebaseAuth.instance
                                                          .signInWithEmailAndPassword(
                                                            email: email,
                                                            password: pass,
                                                          );

                                                      final credential = await Future.any([
                                                        loginFuture,
                                                        Future.delayed(
                                                          const Duration(seconds: 10),
                                                          () => throw TimeoutException('Login timeout'),
                                                        ),
                                                      ]);

                                                      final user = credential.user;
                                                      if (!mounted) return;

                                                      if (user != null) {
                                                        // Add timeout for Firestore operation
                                                        final docFuture = FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(user.uid)
                                                            .get();

                                                        final doc = await Future.any([
                                                          docFuture,
                                                          Future.delayed(
                                                            const Duration(seconds: 10),
                                                            () => throw TimeoutException('Firestore timeout'),
                                                          ),
                                                        ]);

                                                        if (!mounted) return;

                                                        final data = doc.data();
                                                        final accountType = data?['accountType'] ?? 'Farmer';
                                                        final userName = data?['name'] ?? '';

                                                        // Store data in parallel
                                                        await Future.wait([
                                                          storage.write(
                                                            key: 'user_uid',
                                                            value: user.uid,
                                                          ),
                                                          storage.write(
                                                            key: 'account_type',
                                                            value: accountType,
                                                          ),
                                                          storage.write(
                                                            key: 'name',
                                                            value: userName,
                                                          ),
                                                          storage.write(
                                                            key: 'user_name',
                                                            value: userName,
                                                          ),
                                                          storage.write(
                                                            key: 'user_email',
                                                            value: user.email ?? '',
                                                          ),
                                                        ]);

                                                        // Set user identifier for Crashlytics tracking
                                                        await ErrorHandler.setUserIdentifier(
                                                          user.uid,
                                                          email: user.email,
                                                        );
                                                        await ErrorHandler.setCustomKey('account_type', accountType);
                                                        await ErrorHandler.setCustomKey('user_name', userName);

                                                        // AuthWrapper will automatically navigate based on auth state
                                                        // No manual navigation needed here
                                                      }
                                                    } on FirebaseAuthException catch (e) {
                                                      if (!mounted) return;
                                                      String message = 'Login failed';
                                                      switch (e.code) {
                                                        case 'user-not-found':
                                                          message = 'No account found for this email.';
                                                          break;
                                                        case 'wrong-password':
                                                          message = 'Incorrect password.';
                                                          break;
                                                        case 'too-many-requests':
                                                          message = 'Too many attempts. Please try again later.';
                                                          break;
                                                        case 'network-request-failed':
                                                          message = 'Network error. Please check your connection.';
                                                          break;
                                                      }
                                                      showError(message);
                                                    } on TimeoutException {
                                                      if (!mounted) return;
                                                      showError('Connection timeout. Please try again.');
                                                    } catch (e) {
                                                      if (!mounted) return;
                                                      showError('An unexpected error occurred. Please try again.');
                                                    } finally {
                                                      if (mounted) {
                                                        isLoading.value = false;
                                                      }
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF1B4D3E,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 32,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: loading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.5,
                                                        ),
                                                  )
                                                : const Text(
                                                    "Login",
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/recover',
                                            ),
                                            child: const Text(
                                              "Forgot Password?",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                "Don't have an account? ",
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => Navigator.pushReplacementNamed(
                                                  context,
                                                  '/signup',
                                                ),
                                                child: const Text(
                                                  "Sign Up",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
                );
              },
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
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFD9F2E6),
        hintStyle: const TextStyle(fontFamily: 'Poppins'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
