import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/error_handler.dart';
import '../services/validation_service.dart';
import '../shared/theme_helper.dart';

final storage = FlutterSecureStorage();

class AgriSynchSignUpPage extends StatefulWidget {
  const AgriSynchSignUpPage({super.key});

  @override
  State<AgriSynchSignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<AgriSynchSignUpPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String _selectedAccountType = 'Farmer'; // Default to Farmer
  bool _isPasswordVisible = false; // Track password visibility
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
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
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
        foregroundColor: Colors.white,
        title: const Text('Sign Up', style: TextStyle(fontFamily: 'Poppins')),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const SizedBox(height: 16),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      "Welcome to",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: ThemeHelper.getTextColor(isDarkMode),
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
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 16),
                                        _inputField("Name", nameController),
                                        const SizedBox(height: 12),
                                        _inputField("Email", emailController),
                                        const SizedBox(height: 12),
                                        _passwordField(),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Which type of account?",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedAccountType,
                                              isExpanded: true,
                                              dropdownColor: const Color(
                                                0xFF00A862,
                                              ),
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
                                        const SizedBox(height: 24),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final name = nameController.text
                                                  .trim();
                                              final email = emailController.text
                                                  .trim();
                                              final pass = passController.text;

                                              if (name.isEmpty) {
                                                showError(
                                                  "Please enter your name.",
                                                );
                                                return;
                                              }

                                              // Validate inputs using ValidationService
                                              final nameValidation = ValidationService.validateName(name);
                                              if (nameValidation != null) {
                                                showError(nameValidation);
                                                return;
                                              }

                                              final emailValidation = ValidationService.validateEmail(email);
                                              if (emailValidation != null) {
                                                showError(emailValidation);
                                                return;
                                              }

                                              final passwordValidation = ValidationService.validatePassword(pass);
                                              if (passwordValidation != null) {
                                                showError(passwordValidation);
                                                return;
                                              }

                                              // Prepare a reference for a pre-auth Firestore document
                                              final preUserRef = FirebaseFirestore.instance
                                                  .collection('pre_users')
                                                  .doc(); // auto-id

                                              try {
                                                // 1) Save the collected data to Firestore BEFORE creating the Auth account.
                                                //    We mark it as 'pending_auth' so backend/admins can track pending signups if needed.
                                                final preUserData = {
                                                  'name': ValidationService.sanitizeInput(name),
                                                  'email': ValidationService.sanitizeInput(email),
                                                  'accountType': _selectedAccountType,
                                                  'status': 'pending_auth',
                                                  'createdAt': FieldValue.serverTimestamp(),
                                                };

                                                await preUserRef.set(preUserData);
                                                print('Pre-auth Firestore doc created: ${preUserRef.id}');

                                                // 2) Create account with Firebase Auth
                                                final credential =
                                                    await FirebaseAuth.instance
                                                        .createUserWithEmailAndPassword(
                                                          email: email,
                                                          password: pass,
                                                        );

                                                final user = credential.user;
                                                if (user != null) {
                                                  // Send verification email
                                                  await user.sendEmailVerification();
                                                  
                                                  // 3) Move/merge the pre-user data into the canonical 'users' collection keyed by uid
                                                  final userRef = FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(user.uid);

                                                  final userData = {
                                                    'uid': user.uid,
                                                    'name': name,
                                                    'email': email,
                                                    'accountType': _selectedAccountType,
                                                    'createdAt': FieldValue.serverTimestamp(),
                                                  };

                                                  await userRef.set(userData);

                                                  // Optionally delete the pre-auth doc to avoid duplicates
                                                  await preUserRef.delete().catchError((err) {
                                                    // Not critical if delete fails; log for debugging
                                                    print('Warning: failed to delete pre_user doc: $err');
                                                  });

                                                  print("Firestore write completed for user ${user.uid}.");

                                                  await storage.write(
                                                    key: 'user_uid',
                                                    value: user.uid,
                                                  );
                                                  await storage.write(
                                                    key: 'name',
                                                    value: name,
                                                  );
                                                  await storage.write(
                                                    key: 'user_name',
                                                    value: name,
                                                  );
                                                  await storage.write(
                                                    key: 'user_email',
                                                    value: email,
                                                  );
                                                  await storage.write(
                                                    key: 'account_type',
                                                    value: _selectedAccountType,
                                                  );

                                                  // Set user identifier for Crashlytics tracking
                                                  await ErrorHandler.setUserIdentifier(
                                                    user.uid,
                                                    email: user.email,
                                                  );
                                                  await ErrorHandler.setCustomKey('account_type', _selectedAccountType);
                                                  await ErrorHandler.setCustomKey('user_name', name);

                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Signup successful!',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      '/verify',
                                                      arguments: email,
                                                    );
                                                  }
                                                } else {
                                                  // This is unexpected but handle it
                                                  print("createUserWithEmailAndPassword returned null user.");
                                                  // Attempt cleanup of the pre-user doc
                                                  await preUserRef.delete().catchError((_) {});
                                                  showError("Signup failed. Please try again.");
                                                }
                                              } on FirebaseAuthException catch (e) {
                                                // Auth failed — remove the pre-user doc to avoid orphaned records
                                                await preUserRef.delete().catchError((err) {
                                                  print('Error deleting pre_user after auth failure: $err');
                                                });

                                                String message =
                                                    'Signup failed';
                                                if (e.code == 'email-already-in-use') {
                                                  message =
                                                      'Email already registered.';
                                                }
                                                if (e.code == 'weak-password') {
                                                  message =
                                                      'Password too weak.';
                                                }
                                                print("FirebaseAuthException during signup: ${e.code} - ${e.message}");
                                                showError(message);
                                              } catch (e) {
                                                // Any other error — try to clean up the pre-user doc
                                                print("Exception during pre-auth or signup flow: $e");
                                                await preUserRef.delete().catchError((err) {
                                                  print('Error deleting pre_user after exception: $err');
                                                });
                                                showError('Error: $e');
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
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
                                            child: const Text(
                                              "Next",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
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
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: "Password",
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
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
      ),
    );
  }
}
