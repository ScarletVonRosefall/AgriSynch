import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Secret admin portal access
  int _tapCount = 0;
  Timer? _tapTimer;

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
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleSecretTap() {
    _tapCount++;
    
    // Reset timer
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 3), () {
      _tapCount = 0;
    });
    
    // If 15 taps reached, navigate to admin portal
    if (_tapCount >= 15) {
      _tapCount = 0;
      _tapTimer?.cancel();
      Navigator.pushNamed(context, '/admin-portal');
    }
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
    final isDarkMode = _themeNotifier.isDarkMode;
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final ValueNotifier<bool> isLoading = ValueNotifier(false);
    final ValueNotifier<bool> showPassword = ValueNotifier(false);

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
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
                                  GestureDetector(
                                    onTap: _handleSecretTap,
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      "Log in to continue",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: ThemeHelper.getTextColor(isDarkMode),
                                      ),
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
                                                color: Colors.amber.shade50,
                                                border: Border.all(
                                                  color: Colors.orange.shade600,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.15),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: Colors.orange.shade700,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _invalidCharWarning,
                                                      style: TextStyle(
                                                        color: Colors.orange.shade800,
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
                                                        
                                                        // Check if user is banned or suspended
                                                        final isBanned = data?['banned'] == true;
                                                        final suspendedUntil = data?['suspendedUntil'] as Timestamp?;
                                                        final isSuspended = suspendedUntil != null && 
                                                                           suspendedUntil.toDate().isAfter(DateTime.now());
                                                        
                                                        if (isBanned) {
                                                          await FirebaseAuth.instance.signOut();
                                                          showError('Your account has been permanently banned. Reason: ${data?['banReason'] ?? 'Violation of terms'}');
                                                          return;
                                                        }
                                                        
                                                        if (isSuspended) {
                                                          await FirebaseAuth.instance.signOut();
                                                          final suspendedUntilDate = suspendedUntil.toDate();
                                                          showError('Your account is suspended until ${suspendedUntilDate.day}/${suspendedUntilDate.month}/${suspendedUntilDate.year}. Reason: ${data?['banReason'] ?? 'Policy violation'}');
                                                          return;
                                                        }
                                                        
                                                        final accountType = data?['accountType'] ?? 'Farmer';
                                                        final userName = data?['name'] ?? '';
                                                        
                                                        // Debug to verify account type
                                                        showError("Login successful! Account type: $accountType");

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
                                                            Navigator.pushNamedAndRemoveUntil(
                                                              context, 
                                                              '/buyer-home', 
                                                              (route) => false,
                                                            );
                                                          } else {
                                                            Navigator.pushNamedAndRemoveUntil(
                                                              context, 
                                                              '/home', 
                                                              (route) => false,
                                                            );
                                                          }
                                                        } catch (e) {
                                                          showError("Navigation error: $e");
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
