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
        // Don't start auto-check immediately - let user click the button
        // startVerificationCheck();
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
              content: Text('Auto-check stopped. Please use "Check Verification Status" button.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      _checkAttempts++;
      checkEmailVerification();
    });
  }

  Future<void> checkEmailVerification() async {
    if (_navigating || !mounted) return;

    User? user = auth.currentUser;
    if (user == null) {
      _timer?.cancel();
      if (mounted && !_navigating) {
        setState(() => _navigating = true);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! Redirecting...'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        
        // Navigate to home - AuthWrapper will handle the rest
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
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
              content: Text('Verification email sent! Please check your inbox.'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! Redirecting...'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 2),
          ),
        );

        // Add slight delay to show the success message
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        
        // Navigate to home - the AuthWrapper will handle routing based on verification
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please click the link in your email, then tap this button again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification check timed out. Please try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please verify your email address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              "We've sent you a verification link. Click the link in the email to verify your account.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Manual check button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : const Text('I\'ve Verified - Check Now',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Auto-check button (optional)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_timer?.isActive ?? false) ? null : () {
                  startVerificationCheck();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auto-checking every 15 seconds...'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  (_timer?.isActive ?? false) ? Icons.check_circle : Icons.autorenew,
                  color: const Color(0xFF00C853),
                ),
                label: Text(
                  (_timer?.isActive ?? false) ? 'Auto-Check Running...' : 'Start Auto-Check',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF00C853)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF00C853)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : resendVerificationEmail,
                child: const Text(
                  "Resend Verification Email",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
            
            if (_timer?.isActive ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Auto-checking... (${_checkAttempts}/${_maxAttempts})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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