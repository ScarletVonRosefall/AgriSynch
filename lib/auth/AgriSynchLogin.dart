import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/url_opener.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/error_handler.dart';
import '../shared/theme_helper.dart';
import '../shared/input_validator.dart';

// Lighter input formatter for login - only blocks obviously problematic characters
class LightInputValidator extends TextInputFormatter {
  final RegExp allowedPattern;
  final String fieldType;
  final Function(String) onInvalidChar;

  LightInputValidator({
    required this.allowedPattern,
    required this.fieldType,
    required this.onInvalidChar,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if any new characters are invalid
    if (newValue.text.length > oldValue.text.length) {
      String newChar = newValue.text.substring(oldValue.text.length);
      if (!allowedPattern.hasMatch(newChar)) {
        onInvalidChar(fieldType);
        return oldValue; // Reject the invalid character
      }
    }
    
    return newValue;
  }
}

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
  final _themeNotifier = ThemeNotifier();
  
  // State variables for light input validation warnings
  String _invalidCharWarning = '';
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);

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

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLightInvalidCharWarning(String fieldType) {
    setState(() {
      _showWarning = true;
      switch (fieldType) {
        case 'email':
          _invalidCharWarning = 'Please use standard email characters';
          break;
        case 'password':
          _invalidCharWarning = 'Characters like < > { } [ ] | \\ are not allowed';
          break;
      }
    });

    // Hide warning after 2 seconds (shorter for login)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showWarning = false;
          _invalidCharWarning = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final ValueNotifier<bool> isLoading = ValueNotifier(false);
    final ValueNotifier<bool> showPassword = ValueNotifier(false);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        left: MediaQuery.of(context).size.width <= 900,
        right: MediaQuery.of(context).size.width <= 900,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 600 ? 16 : (MediaQuery.of(context).size.width > 900 ? 0 : 40),
                        ),
                        child: MediaQuery.of(context).size.width > 900
                            ? Row(
                                children: [
                                  _buildLeftInfoPanel(),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 450),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 48),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1A2332),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.5),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(32),
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
                                                  iconPrefix: Icons.email_outlined,
                                                ),
                                                const SizedBox(height: 12),
                                                ValueListenableBuilder<bool>(
                                                  valueListenable: showPassword,
                                                  builder: (context, value, child) {
                                                    return _inputField(
                                                      "Password",
                                                      passController,
                                                      obscure: !value,
                                                      iconPrefix: Icons.lock_outline,
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          value
                                                              ? Icons.visibility
                                                              : Icons.visibility_off,
                                                          color: const Color(0xFF64B5A6),
                                                        ),
                                                        onPressed: () =>
                                                            showPassword.value = !value,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                // Light warning indicator for invalid characters
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 250),
                                                  height: _showWarning ? 32 : 0,
                                                  child: _showWarning
                                                      ? Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF37474F),
                                                            border: Border.all(
                                                              color: const Color(0xFFFFA726),
                                                              width: 1.5,
                                                            ),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons.info_outline,
                                                                color: Color(0xFFFFA726),
                                                                size: 14,
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  _invalidCharWarning,
                                                                  style: const TextStyle(
                                                                    color: Color(0xFFFFB74D),
                                                                    fontSize: 11,
                                                                    fontFamily: 'Poppins',
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                                const SizedBox(height: 16),
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

                                                                // Sanitize and validate inputs
                                                                final sanitizedEmail = InputValidator.sanitizeEmail(email);
                                                                final emailError = InputValidator.validateEmail(sanitizedEmail);
                                                                
                                                                if (emailError != null) {
                                                                  showError(emailError);
                                                                  return;
                                                                }
                                                                
                                                                if (pass.length > InputValidator.maxPasswordLength) {
                                                                  showError("Password is too long");
                                                                  return;
                                                                }
                                                                
                                                                // Check for dangerous content
                                                                if (InputValidator.containsDangerousContent(email) ||
                                                                    InputValidator.containsDangerousContent(pass)) {
                                                                  showError("Invalid characters detected in login credentials");
                                                                  return;
                                                                }

                                                                // Capture stable objects before async gaps
                                                                final messenger = ScaffoldMessenger.of(context);
                                                                final navigator = Navigator.of(context);
                                                                if (!mounted) return;
                                                                isLoading.value = true;

                                                                try {
                                                                  // Add timeout for Firebase operations
                                                                  final loginFuture = FirebaseAuth.instance
                                                                      .signInWithEmailAndPassword(
                                                                        email: sanitizedEmail,
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
                                                                    // messenger and navigator were captured earlier
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
                                                                    
                                                                    // Check if user document exists (not deleted)
                                                                    if (data == null) {
                                                                      await FirebaseAuth.instance.signOut();
                                                                      if (!mounted) return;
                                                                      messenger.showSnackBar(
                                                                        const SnackBar(content: Text('This account has been deleted and no longer exists.')),
                                                                      );
                                                                      return;
                                                                    }
                                                                    
                                                                    // Check if user is banned or suspended
                                                                    final isBanned = data['banned'] == true;
                                                                    final suspendedUntil = data['suspendedUntil'] as Timestamp?;
                                                                    final isSuspended = suspendedUntil != null && 
                                                                                       suspendedUntil.toDate().isAfter(DateTime.now());
                                                                    
                                                                    if (isBanned) {
                                                                      await FirebaseAuth.instance.signOut();
                                                                      if (!mounted) return;
                                                                      messenger.showSnackBar(
                                                                        SnackBar(content: Text('Your account has been permanently banned. Reason: ${data['banReason'] ?? 'Violation of terms'}')),
                                                                      );
                                                                      return;
                                                                    }
                                                                    
                                                                    if (isSuspended) {
                                                                      await FirebaseAuth.instance.signOut();
                                                                      if (!mounted) return;
                                                                      final suspendedUntilDate = suspendedUntil.toDate();
                                                                      messenger.showSnackBar(
                                                                        SnackBar(content: Text('Your account is suspended until ${suspendedUntilDate.day}/${suspendedUntilDate.month}/${suspendedUntilDate.year}. Reason: ${data['banReason'] ?? 'Policy violation'}')),
                                                                      );
                                                                      return;
                                                                    }
                                                                    
                                                                    final accountType = data['accountType'] ?? 'Farmer';
                                                                    final userName = data['name'] ?? '';

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
                                                                    
                                                                    // Force navigation after successful login
                                                                    if (!mounted) return;

                                                                    try {
                                                                      // Navigate based on account type with complete stack replacement
                                                                      if (accountType == 'Buyer') {
                                                                        navigator.pushNamedAndRemoveUntil(
                                                                          '/buyer-home',
                                                                          (route) => false,
                                                                        );
                                                                      } else {
                                                                        navigator.pushNamedAndRemoveUntil(
                                                                          '/home',
                                                                          (route) => false,
                                                                        );
                                                                      }
                                                                    } catch (e) {
                                                                      messenger.showSnackBar(
                                                                        SnackBar(content: Text("Navigation error: $e")),
                                                                      );
                                                                    }
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
                                                                  // Use captured messenger to avoid using BuildContext across async gaps
                                                                  messenger.showSnackBar(SnackBar(content: Text(message)));
                                                                } on TimeoutException {
                                                                  if (!mounted) return;
                                                                  messenger.showSnackBar(const SnackBar(content: Text('Connection timeout. Please try again.')));
                                                                } catch (e) {
                                                                  if (!mounted) return;
                                                                  messenger.showSnackBar(const SnackBar(content: Text('An unexpected error occurred. Please try again.')));
                                                                } finally {
                                                                  if (mounted) {
                                                                    isLoading.value = false;
                                                                  }
                                                                }
                                                              },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF1DBF73),
                                                          disabledBackgroundColor: const Color(0xFF555B62),
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 32,
                                                            vertical: 14,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          elevation: 4,
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
                                                            color: Color(0xFF64B5A6),
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
                                                              color: Color(0xFFB0BEC5),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () => Navigator.pushNamed(
                                                              context,
                                                              '/signup',
                                                            ),
                                                            child: const Text(
                                                              "Sign Up",
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontSize: 13,
                                                                color: Color(0xFF1DBF73),
                                                                fontWeight: FontWeight.bold,
                                                                decoration: TextDecoration.underline,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 16),
                                                        Center(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () async {
                                                            const url = 'https://github.com/ScarletVonRosefall/AgriSynch/releases/download/v.1.0.3/Agrisynch_V2.apk';
                                                            final messenger = ScaffoldMessenger.of(context);
                                                            final ok = await openUrl(url);
                                                            if (!ok) {
                                                              messenger.showSnackBar(
                                                                const SnackBar(content: Text('Could not open download link.')),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF1DBF73),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                            elevation: 4,
                                                          ),
                                                          icon: const Icon(Icons.android, color: Colors.white),
                                                          label: const Text('Download APK (Android)', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Center(
                                                        child: Text(
                                                          'Tip: This APK is downloaded via your browser. You may need to allow "Install unknown apps" or "Unknown sources" in your Android settings before installing.',
                                                          textAlign: TextAlign.center,
                                                          style: const TextStyle(
                                                            fontFamily: 'Poppins',
                                                            fontSize: 12,
                                                            color: Color(0xFFB0BEC5),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                Column(
                                  children: [
                                    const Text(
                                      "Log in to continue",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFFB0BEC5),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "AgriSynch",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 36,
                                        color: Color(0xFF1DBF73),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
                                              height: 80,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 48),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2332),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(32),
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
                                      iconPrefix: Icons.email_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: showPassword,
                                      builder: (context, value, child) {
                                        return _inputField(
                                          "Password",
                                          passController,
                                          obscure: !value,
                                          iconPrefix: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              value
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: const Color(0xFF64B5A6),
                                            ),
                                            onPressed: () =>
                                                showPassword.value = !value,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Light warning indicator for invalid characters
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      height: _showWarning ? 32 : 0,
                                      child: _showWarning
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF37474F),
                                                border: Border.all(
                                                  color: const Color(0xFFFFA726),
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline,
                                                    color: Color(0xFFFFA726),
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _invalidCharWarning,
                                                      style: const TextStyle(
                                                        color: Color(0xFFFFB74D),
                                                        fontSize: 11,
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 16),
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

                                                    // Sanitize and validate inputs
                                                    final sanitizedEmail = InputValidator.sanitizeEmail(email);
                                                    final emailError = InputValidator.validateEmail(sanitizedEmail);
                                                    
                                                    if (emailError != null) {
                                                      showError(emailError);
                                                      return;
                                                    }
                                                    
                                                    if (pass.length > InputValidator.maxPasswordLength) {
                                                      showError("Password is too long");
                                                      return;
                                                    }
                                                    
                                                    // Check for dangerous content
                                                    if (InputValidator.containsDangerousContent(email) ||
                                                        InputValidator.containsDangerousContent(pass)) {
                                                      showError("Invalid characters detected in login credentials");
                                                      return;
                                                    }

                                                    // Capture stable objects before async gaps
                                                    final messenger = ScaffoldMessenger.of(context);
                                                    final navigator = Navigator.of(context);
                                                    if (!mounted) return;
                                                    isLoading.value = true;

                                                    try {
                                                      // Add timeout for Firebase operations
                                                      final loginFuture = FirebaseAuth.instance
                                                          .signInWithEmailAndPassword(
                                                            email: sanitizedEmail,
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
                                                        // messenger and navigator were captured earlier
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
                                                        
                                                        // Check if user document exists (not deleted)
                                                        if (data == null) {
                                                          await FirebaseAuth.instance.signOut();
                                                          if (!mounted) return;
                                                          messenger.showSnackBar(
                                                            const SnackBar(content: Text('This account has been deleted and no longer exists.')),
                                                          );
                                                          return;
                                                        }
                                                        
                                                        // Check if user is banned or suspended
                                                        final isBanned = data['banned'] == true;
                                                        final suspendedUntil = data['suspendedUntil'] as Timestamp?;
                                                        final isSuspended = suspendedUntil != null && 
                                                                           suspendedUntil.toDate().isAfter(DateTime.now());
                                                        
                                                        if (isBanned) {
                                                          await FirebaseAuth.instance.signOut();
                                                          if (!mounted) return;
                                                          messenger.showSnackBar(
                                                            SnackBar(content: Text('Your account has been permanently banned. Reason: ${data['banReason'] ?? 'Violation of terms'}')),
                                                          );
                                                          return;
                                                        }
                                                        
                                                        if (isSuspended) {
                                                          await FirebaseAuth.instance.signOut();
                                                          if (!mounted) return;
                                                          final suspendedUntilDate = suspendedUntil.toDate();
                                                          messenger.showSnackBar(
                                                            SnackBar(content: Text('Your account is suspended until ${suspendedUntilDate.day}/${suspendedUntilDate.month}/${suspendedUntilDate.year}. Reason: ${data['banReason'] ?? 'Policy violation'}')),
                                                          );
                                                          return;
                                                        }
                                                        
                                                        final accountType = data['accountType'] ?? 'Farmer';
                                                        final userName = data['name'] ?? '';

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
                                                        
                                                        // Force navigation after successful login
                                                        if (!mounted) return;

                                                        try {
                                                          // Navigate based on account type with complete stack replacement
                                                          if (accountType == 'Buyer') {
                                                            navigator.pushNamedAndRemoveUntil(
                                                              '/buyer-home',
                                                              (route) => false,
                                                            );
                                                          } else {
                                                            navigator.pushNamedAndRemoveUntil(
                                                              '/home',
                                                              (route) => false,
                                                            );
                                                          }
                                                        } catch (e) {
                                                          messenger.showSnackBar(
                                                            SnackBar(content: Text("Navigation error: $e")),
                                                          );
                                                        }
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
                                                      // Use captured messenger to avoid using BuildContext across async gaps
                                                      messenger.showSnackBar(SnackBar(content: Text(message)));
                                                    } on TimeoutException {
                                                      if (!mounted) return;
                                                      messenger.showSnackBar(const SnackBar(content: Text('Connection timeout. Please try again.')));
                                                    } catch (e) {
                                                      if (!mounted) return;
                                                      messenger.showSnackBar(const SnackBar(content: Text('An unexpected error occurred. Please try again.')));
                                                    } finally {
                                                      if (mounted) {
                                                        isLoading.value = false;
                                                      }
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1DBF73),
                                              disabledBackgroundColor: const Color(0xFF555B62),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 4,
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
                                                color: Color(0xFF64B5A6),
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
                                                  color: Color(0xFFB0BEC5),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => Navigator.pushNamed(
                                                  context,
                                                  '/signup',
                                                ),
                                                child: const Text(
                                                  "Sign Up",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 13,
                                                    color: Color(0xFF1DBF73),
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                            Center(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                const url = 'https://github.com/ScarletVonRosefall/AgriSynch/releases/download/v.1.0.3/Agrisynch_V2.apk';
                                                final messenger = ScaffoldMessenger.of(context);
                                                final ok = await openUrl(url);
                                                if (!ok) {
                                                  messenger.showSnackBar(
                                                    const SnackBar(content: Text('Could not open download link.')),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1DBF73),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 4,
                                              ),
                                              icon: const Icon(Icons.android, color: Colors.white),
                                              label: const Text('Download APK (Android)', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Center(
                                            child: Text(
                                              'Tip: This APK is downloaded via your browser. You may need to allow "Install unknown apps" or "Unknown sources" in your Android settings before installing.',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: Color(0xFFB0BEC5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    IconData? iconPrefix,
  }) {
    // Light validation - only block obviously problematic characters
    List<TextInputFormatter> formatters = [];
    
    if (hint == "Email") {
      // Email: block < > { } [ ] | \ and quotes - keep it simple for login
      formatters.add(LightInputValidator(
        allowedPattern: RegExp(r"[^<>{}[\]|\\]"),
        fieldType: 'email',
        onInvalidChar: _showLightInvalidCharWarning,
      ));
    } else if (hint == "Password") {
      // Password: only block the most problematic characters like < > { } [ ] |
      formatters.add(LightInputValidator(
        allowedPattern: RegExp(r"[^<>{}[\]|\\]"),
        fieldType: 'password',
        onInvalidChar: _showLightInvalidCharWarning,
      ));
    }
    
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFFE0E0E0),
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF263238),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF78909C),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: iconPrefix != null
            ? Icon(
                iconPrefix,
                color: const Color(0xFF64B5A6),
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF37474F),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF37474F),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1DBF73),
            width: 2,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // Left info panel for desktop split-screen
  Widget _buildLeftInfoPanel() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1DBF73).withOpacity(0.1),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Logo
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
            const SizedBox(height: 32),
            // Main tagline
            const Text(
              'Connecting Harvests to Homes',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1DBF73),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            // Value bullets
            _buildValueBullet(
              icon: Icons.agriculture,
              title: 'Direct Market Access',
              description: 'Connect with buyers and sell your produce directly',
            ),
            const SizedBox(height: 16),
            _buildValueBullet(
              icon: Icons.trending_up,
              title: 'Fair Pricing',
              description: 'Transparent pricing with no hidden fees or middlemen',
            ),
            const SizedBox(height: 16),
            _buildValueBullet(
              icon: Icons.location_on,
              title: 'Local Community',
              description: 'Build relationships with local farmers and buyers',
            ),
          ],
          ),
        ),
      ),
    );
  }

  // Helper widget for value bullets
  Widget _buildValueBullet({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1DBF73).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1DBF73), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFFB0BEC5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
