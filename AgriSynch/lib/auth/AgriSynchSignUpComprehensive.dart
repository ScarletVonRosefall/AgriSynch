import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/error_handler.dart';
import '../shared/theme_helper.dart';
import '../shared/input_validator.dart';

final storage = FlutterSecureStorage();

class AgriSynchComprehensiveSignUpPage extends StatefulWidget {
  const AgriSynchComprehensiveSignUpPage({super.key});

  @override
  State<AgriSynchComprehensiveSignUpPage> createState() =>
      _ComprehensiveSignUpPageState();
}

class _ComprehensiveSignUpPageState extends State<AgriSynchComprehensiveSignUpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Basic Info Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _surnameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();

  // Profile Info Controllers
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _themeNotifier = ThemeNotifier();

  String _selectedAccountType = 'Farmer';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _surnameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      setState(() => _isLoading = true);

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required. Please enable it in settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location retrieved successfully'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithAllData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get your location before signing up.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Sanitize and validate
      final sanitizedEmail = InputValidator.sanitizeEmail(email);
      final emailError = InputValidator.validateEmail(sanitizedEmail);
      if (emailError != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(emailError), backgroundColor: Colors.red),
        );
        return;
      }

      final passwordError =
          InputValidator.validatePassword(password, isSignup: true);
      if (passwordError != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
        );
        return;
      }

      // Build full name
      final fullName = _buildFullName();

      // 1) Create Firebase Auth account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Small delay to ensure auth token is propagated
        await Future.delayed(const Duration(milliseconds: 500));

        // Send verification email
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('Warning: Could not send verification email: $e');
        }

        // 2) Create user document in Firestore with ALL profile data
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final userData = {
          'uid': user.uid,
          'email': sanitizedEmail,
          'name': fullName,
          'surname': _surnameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
          'accountType': _selectedAccountType,
          'userType': _selectedAccountType.toLowerCase(),
          'profileComplete': true, // Mark as complete since all fields are filled
          'createdAt': FieldValue.serverTimestamp(),
        };

        await userRef.set(userData).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firestore write timeout');
          },
        );

        debugPrint('✅ User account created with complete profile');

        // Save to local storage
        await storage.write(key: 'user_uid', value: user.uid);
        await storage.write(key: 'user_email', value: sanitizedEmail);
        await storage.write(key: 'user_name', value: fullName);
        await storage.write(key: 'account_type', value: _selectedAccountType);
        await storage.write(key: 'user_location', value: _locationController.text);
        await storage.write(key: 'latitude', value: _latitude.toString());
        await storage.write(key: 'longitude', value: _longitude.toString());

        // Set Crashlytics user identifier
        await ErrorHandler.setUserIdentifier(
          user.uid,
          email: user.email,
        );
        await ErrorHandler.setCustomKey('account_type', _selectedAccountType);

        if (!mounted) return;

        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Signup successful! Please verify your email.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        navigator.pushReplacementNamed(
          '/verify',
          arguments: sanitizedEmail,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email already registered. Please login instead.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException: ${e.code} - ${e.message}');
      String message = 'Firestore error: ${e.message}';
      if (e.code == 'permission-denied') {
        message = 'Permission denied. Check your internet connection.';
      }
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('❌ Exception during signup: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildFullName() {
    final surname = _surnameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();

    final parts = <String>[];
    if (surname.isNotEmpty) parts.add(surname);
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName.isNotEmpty) parts.add(middleName);

    return parts.join(', ');
  }

  TapGestureRecognizer _tapGestureRecognizer() {
    return TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushReplacementNamed(context, '/login');
      };
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isPassword = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isMultiline = false,
    IconData? prefixIcon,
  }) {
    final isDarkMode = _themeNotifier.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : isPhone
                  ? TextInputType.phone
                  : isMultiline
                      ? TextInputType.multiline
                      : TextInputType.text,
          maxLines: isMultiline ? 3 : 1,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(
                          () => _isPasswordVisible = !_isPasswordVisible);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Poppins',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Create Your Account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile in one step',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Type Selector
                  Text(
                    'Account Type',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00C853),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAccountType,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      dropdownColor:
                          isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 'Farmer',
                          child: Text('🌾 Farmer'),
                        ),
                        DropdownMenuItem(
                          value: 'Buyer',
                          child: Text('🛒 Buyer'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedAccountType = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section: Basic Information
                  Text(
                    '📧 Basic Information',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildTextField('Email', _emailController,
                      hint: 'your@email.com',
                      isEmail: true,
                      prefixIcon: Icons.email),
                  const SizedBox(height: 12),

                  _buildTextField('Password', _passwordController,
                      hint: 'Min. 6 characters',
                      isPassword: true,
                      prefixIcon: Icons.lock),
                  const SizedBox(height: 20),

                  // Section: Personal Information
                  Text(
                    '👤 Personal Information',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildTextField('Surname', _surnameController,
                      hint: 'e.g., Santos',
                      prefixIcon: Icons.person),
                  const SizedBox(height: 12),

                  _buildTextField('First Name', _firstNameController,
                      hint: 'e.g., Juan',
                      prefixIcon: Icons.person),
                  const SizedBox(height: 12),

                  _buildTextField('Middle Name', _middleNameController,
                      hint: 'e.g., Dela Cruz',
                      prefixIcon: Icons.person),
                  const SizedBox(height: 12),

                  _buildTextField('Nickname', _nicknameController,
                      hint: 'e.g., Juan',
                      prefixIcon: Icons.person_outline),
                  const SizedBox(height: 20),

                  // Section: Contact & Location
                  Text(
                    '📍 Contact & Location',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildTextField('Phone Number', _phoneController,
                      hint: '+63 9XX XXX XXXX',
                      isPhone: true,
                      prefixIcon: Icons.phone),
                  const SizedBox(height: 12),

                  // Location with Map Button
                  Text(
                    'Location (Coordinates)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Tap "Get My Location" to set',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Location is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getUserLocation,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Get Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section: Bio
                  Text(
                    '📝 Bio/Description',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    'Tell us about yourself',
                    _bioController,
                    hint:
                        'e.g., I have 10 years of farming experience...',
                    isMultiline: true,
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 20),

                  // Terms & Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        activeColor: const Color(0xFF00C853),
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpWithAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Complete Registration',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color:
                              isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ),
                            recognizer: _tapGestureRecognizer(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
