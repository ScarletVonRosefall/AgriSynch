import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/theme_helper.dart';
import 'auth_service.dart';

class AgriSynchRecoverPage extends StatefulWidget {
  const AgriSynchRecoverPage({super.key});

  @override
  State<AgriSynchRecoverPage> createState() => _AgriSynchRecoverPageState();
}

class _AgriSynchRecoverPageState extends State<AgriSynchRecoverPage> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool _isSending = false;
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    if (_isSending) return;

    final email = emailController.text.trim();
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (!mounted) return;

    try {
      _isSending = true;
      setState(() => isLoading = true);

      // Use AuthService to send reset email (includes user existence check)
      final emailSent = await AuthService.sendPasswordResetEmail(email);

      if (!mounted) return;

      if (!emailSent) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No account found with this email address. This account may have been deleted.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Recovery email sent! Please check your inbox and spam folder.'),
          backgroundColor: Color(0xFF00A862),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        navigator.pushReplacementNamed('/login');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address format';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email address';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      _isSending = false;
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Forgot Your Password?",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white,
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
                    Image.asset('assets/logo.png', height: 100),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Account Recovery",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Forgot your password? Enter your email and we'll send you a recovery link.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _inputField("Email", emailController),
                    const SizedBox(height: 24),
                    // Debug info text
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendRecoveryEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DBF73),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Send Recovery Link",
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF263238),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white70,
        ),
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