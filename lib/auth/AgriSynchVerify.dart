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
    extends State<AgriSynchEmailVerificationPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  final TextEditingController codeController = TextEditingController();

  Timer? _timer;
  bool _navigating = false;

  int _checkAttempts = 0;
  static const int _maxAttempts = 10;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
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
            backgroundColor: Color(0xFF1DBF73),
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
              backgroundColor: Color(0xFF1DBF73),
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
            backgroundColor: Color(0xFF1DBF73),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isDesktop
            ? _buildDesktopLayout()
            : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel with gradient
        Expanded(
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
                  // Animated Logo
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
                    'Verify Your Account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1DBF73),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Features
                  _buildVerificationBenefit(
                    icon: Icons.security,
                    title: 'Secure Account',
                    description: 'Email verification protects your account',
                  ),
                  const SizedBox(height: 16),
                  _buildVerificationBenefit(
                    icon: Icons.mail_outline,
                    title: 'Quick Process',
                    description: 'Just click the link we sent to your email',
                  ),
                  const SizedBox(height: 16),
                  _buildVerificationBenefit(
                    icon: Icons.check_circle_outline,
                    title: 'Start Using',
                    description: 'Full access to AgriSynch once verified',
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right panel with verification form
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We\'ve sent a verification link to your email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFFB0BEC5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    // Resend button
                    ElevatedButton(
                      onPressed: isLoading ? null : resendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DBF73),
                        disabledBackgroundColor: const Color(0xFF555B62),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Check button
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : verifyEmail,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'I\'ve Already Verified - Check Now',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF1DBF73)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: const Color(0xFF1DBF73),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '💡 Tip: Check your spam/junk folder if you don\'t see the email.',
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify Email',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'ve sent a verification link to your email. Please click the link to verify your account.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFFB0BEC5),
              ),
            ),
            const SizedBox(height: 32),
            _buildStatusCard(),
            const SizedBox(height: 32),
            // Resend button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DBF73),
                  disabledBackgroundColor: const Color(0xFF555B62),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
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
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Check button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : verifyEmail,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'I\'ve Already Verified - Check Now',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF1DBF73)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF1DBF73),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Tip: Check your spam/junk folder if you don\'t see the email.',
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

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1DBF73).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1DBF73),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: const Color(0xFF1DBF73),
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
                  'Auto-Checking Email Verification',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1DBF73),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Checking every 15 seconds... ($_checkAttempts/$_maxAttempts)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFB0BEC5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBenefit({
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

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    codeController.dispose();
    super.dispose();
  }
}
