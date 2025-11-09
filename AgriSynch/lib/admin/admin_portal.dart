import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/theme_helper.dart';
import '../services/validation_service.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final storage = FlutterSecureStorage();
  final _themeNotifier = ThemeNotifier();

  // Sign In controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final ValueNotifier<bool> _signInLoading = ValueNotifier(false);
  final ValueNotifier<bool> _showSignInPassword = ValueNotifier(false);

  // Sign Up controllers
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final ValueNotifier<bool> _signUpLoading = ValueNotifier(false);
  final ValueNotifier<bool> _showSignUpPassword = ValueNotifier(false);
  final ValueNotifier<bool> _showConfirmPassword = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signUpNameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleAdminSignIn() async {
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password");
      return;
    }

    _signInLoading.value = true;

    try {
      // Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Check if user is actually an admin
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        final isAdmin = data?['isAdmin'] ?? false;

        if (!isAdmin) {
          // Not an admin - sign them out
          await FirebaseAuth.instance.signOut();
          _showError("Access denied: This is not an admin account");
          return;
        }

        // Store admin credentials
        await storage.write(key: 'user_uid', value: user.uid);
        await storage.write(key: 'account_type', value: 'Admin');
        await storage.write(key: 'name', value: data?['name'] ?? 'Admin');
        await storage.write(key: 'is_admin', value: 'true');

        if (!mounted) return;
        _showSuccess("Admin sign-in successful!");

        // Navigate to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign-in failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No admin account found for this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
      }
      _showError(message);
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        _signInLoading.value = false;
      }
    }
  }

  Future<void> _handleAdminSignUp() async {
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text.trim();
    final confirmPassword = _signUpConfirmPasswordController.text.trim();
    final name = _signUpNameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    final emailError = ValidationService.validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final passwordError = ValidationService.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (name.length < 2) {
      _showError("Name must be at least 2 characters");
      return;
    }

    _signUpLoading.value = true;

    try {
      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Create admin user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'isAdmin': true,  // 🔑 THE MAGIC FLAG!
          'accountType': 'Admin',
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': true,
        });

        // Store admin credentials
        await storage.write(key: 'user_uid', value: user.uid);
        await storage.write(key: 'account_type', value: 'Admin');
        await storage.write(key: 'name', value: name);
        await storage.write(key: 'is_admin', value: 'true');

        if (!mounted) return;
        _showSuccess("Admin account created successfully!");

        // Navigate to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign-up failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
      }
      _showError(message);
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        _signUpLoading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A862),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Portal',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSignInTab(),
          _buildSignUpTab(),
        ],
      ),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Color(0xFF00A862),
          ),
          const SizedBox(height: 20),
          const Text(
            'Admin Sign In',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A862),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildTextField(
            controller: _signInEmailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _showSignInPassword,
            builder: (context, show, child) {
              return _buildTextField(
                controller: _signInPasswordController,
                label: 'Password',
                icon: Icons.lock,
                obscureText: !show,
                suffixIcon: IconButton(
                  icon: Icon(show ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => _showSignInPassword.value = !show,
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          ValueListenableBuilder<bool>(
            valueListenable: _signInLoading,
            builder: (context, loading, child) {
              return ElevatedButton(
                onPressed: loading ? null : _handleAdminSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A862),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sign In as Admin',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.person_add,
            size: 80,
            color: Color(0xFF00A862),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Admin Account',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A862),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildTextField(
            controller: _signUpNameController,
            label: 'Full Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpEmailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _showSignUpPassword,
            builder: (context, show, child) {
              return _buildTextField(
                controller: _signUpPasswordController,
                label: 'Password',
                icon: Icons.lock,
                obscureText: !show,
                suffixIcon: IconButton(
                  icon: Icon(show ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => _showSignUpPassword.value = !show,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _showConfirmPassword,
            builder: (context, show, child) {
              return _buildTextField(
                controller: _signUpConfirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: !show,
                suffixIcon: IconButton(
                  icon: Icon(show ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => _showConfirmPassword.value = !show,
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          ValueListenableBuilder<bool>(
            valueListenable: _signUpLoading,
            builder: (context, loading, child) {
              return ElevatedButton(
                onPressed: loading ? null : _handleAdminSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A862),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Admin Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Poppins'),
        prefixIcon: Icon(icon, color: const Color(0xFF00A862)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00A862)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00A862), width: 2),
        ),
      ),
    );
  }
}
