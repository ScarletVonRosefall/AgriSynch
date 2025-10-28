import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class AgriSynchRecoverPage extends StatefulWidget {
  const AgriSynchRecoverPage({super.key});

  @override
  State<AgriSynchRecoverPage> createState() => _AgriSynchRecoverPageState();
}

class _AgriSynchRecoverPageState extends State<AgriSynchRecoverPage> {
  final emailController = TextEditingController();
  bool isLoading = false;

  bool _isSending = false;

  Future<void> _sendRecoveryEmail() async {
    if (_isSending) return;

    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (!mounted) return;

    try {
      _isSending = true;
      setState(() => isLoading = true);

      // Try to send reset email directly through Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery email sent! Please check your inbox and spam folder.'),
          backgroundColor: Color(0xFF00A862),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
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
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Forgot Your Password?",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
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
                  color: const Color(0xFF00A862),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Debug Info:",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  "Firebase Error: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red),
                                );
                              }
                              
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  "Checking Firebase status...",
                                  style: TextStyle(color: Colors.white),
                                );
                              }

                              final auth = FirebaseAuth.instance;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Firebase Status:",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const Text(
                                    "- Connection: Active",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    "- Auth State: ${auth.currentUser != null ? 'Signed In' : 'Not Signed In'}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  if (emailController.text.isNotEmpty) Text(
                                    "- Checking Email: ${emailController.text}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    "- Platform: ${defaultTargetPlatform.toString()}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    "- Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  if (auth.currentUser != null) ...[
                                    Text(
                                      "- Current User: ${auth.currentUser?.email}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      "- Email Verified: ${auth.currentUser?.emailVerified}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendRecoveryEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
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