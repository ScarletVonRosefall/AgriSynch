import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AgriSynchEmailVerificationPage extends StatefulWidget {
  final String? email;
  const AgriSynchEmailVerificationPage({super.key, this.email});

  @override
  State<AgriSynchEmailVerificationPage> createState() =>
      _AgriSynchEmailVerificationPageState();
}

class _AgriSynchEmailVerificationPageState
    extends State<AgriSynchEmailVerificationPage> {
  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  final TextEditingController codeController = TextEditingController();

  Timer? _timer;
  bool _navigating = false;

  int _checkAttempts = 0;
  static const int _maxAttempts = 10; // 10 checks maximum (10 * 15 seconds = 2.5 minutes)

  @override
  void initState() {
    super.initState();
    _initializeVerification();
  }

  Future<void> _initializeVerification() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      final user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        // Start automatic verification checking immediately
        startVerificationCheck();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void startVerificationCheck() {
    _timer?.cancel();
    _checkAttempts = 0;
    // Check every 15 seconds instead of 3 seconds to avoid rate limits
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_checkAttempts >= _maxAttempts) {
        _timer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-check completed. Email may still need verification.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      _checkAttempts++;
      _autoCheckEmailVerification();
    });
    
    // Do the first check immediately
    _autoCheckEmailVerification();
  }

  Future<void> _autoCheckEmailVerification() async {
    if (_navigating || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    User? user = auth.currentUser;
    if (user == null) {
      _timer?.cancel();
      if (mounted && !_navigating) {
        setState(() => _navigating = true);
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }

    try {
      await user.reload();
      user = auth.currentUser;

      if (user?.emailVerified == true) {
        _timer?.cancel();
        if (!mounted || _navigating) return;

        setState(() => _navigating = true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Email verified successfully! Redirecting...'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to home - AuthWrapper will handle the rest
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } catch (e) {
      // Avoid print in production - keep minimal logging
      debugPrint('Error checking email verification: $e');
    }
  }

  Future<void> resendVerificationEmail() async {
    setState(() => isLoading = true);
    try {
      User? user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Verification email sent! Please check your inbox.'),
              backgroundColor: Color(0xFF00C853),
              duration: Duration(seconds: 3),
            ),
          );
          // Restart auto-check when user resends
          startVerificationCheck();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> verifyEmail() async {
    if (!mounted || _navigating || isLoading) return;
    
    setState(() => isLoading = true);
    
    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      User? user = auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Reload user to get latest verification status
      await user.reload();
      user = auth.currentUser; // Get fresh user instance
      
      if (user?.emailVerified == true) {
        if (!mounted) return;

        setState(() => _navigating = true);
        _timer?.cancel(); // Stop the auto-check timer

        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Email verified successfully! Redirecting...'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 2),
          ),
        );

        // Add slight delay to show the success message
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;

        // Navigate to home - the AuthWrapper will handle routing based on verification
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        if (!mounted) return;

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please click the verification link in your email.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Verification check timed out. Please try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted && !_navigating) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify Your Email",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "We've sent a verification link to your email. Please click the link in the email to verify your account.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Auto-checking status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00C853),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF00C853),
                      strokeWidth: 2,
                      value: _checkAttempts / _maxAttempts,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Auto-Checking Email Verification",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Checking every 15 seconds... ($_checkAttempts/$_maxAttempts)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              "Haven't received the email?",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            
            // Resend button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        'Resend Verification Email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Manual check button (for users who already clicked the link but auto-check didn't detect it)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : verifyEmail,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'I\'ve Already Verified - Check Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF00C853)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF00C853),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((0.05 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "💡 Tip: Check your spam/junk folder if you don't see the verification email.",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
  }
}