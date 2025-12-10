import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/error_handler.dart';
import '../shared/theme_helper.dart';
import '../shared/input_validator.dart';
import '../shared/google_location_picker.dart';

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

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _themeNotifier = ThemeNotifier();

  String _selectedAccountType = 'Buyer';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  double? _latitude;
  double? _longitude;
  String? _selectedAddress;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const GoogleLocationPickerPage(),
      ),
    );

    if (result != null && mounted) {
      print('Location received from picker: ${result.address} (${result.latitude}, ${result.longitude})');
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _selectedAddress = result.address;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Location saved! Ready to sign up.')),
            ],
          ),
          backgroundColor: const Color(0xFF1DBF73),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy Policy')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        final userData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'accountType': _selectedAccountType,
          'address': _selectedAddress,
          'location': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
          'acceptedTermsAndPrivacy': true,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        print('Saving user data to Firestore: $userData');
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
        
        print('User data saved successfully to Firestore!');

        String? token = await user.getIdToken();
        if (token != null) {
          await storage.write(key: 'auth_token', value: token);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-up successful!')),
          );
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = ErrorHandler.getErrorMessage(e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFFE0E0E0),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFFB0BEC5),
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF78909C),
        ),
        filled: true,
        fillColor: const Color(0xFF263238),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        suffixIcon: suffixIcon != null ? Padding(
          padding: const EdgeInsets.only(right: 8),
          child: suffixIcon,
        ) : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = true; // Force dark mode
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing: adapt to mobile, tablet, and desktop
    double maxWidth;
    double horizontalPadding;
    if (screenWidth < 480) {
      // Small mobile
      maxWidth = double.infinity;
      horizontalPadding = 16;
    } else if (screenWidth < 768) {
      // Large mobile/small tablet
      maxWidth = double.infinity;
      horizontalPadding = 20;
    } else if (screenWidth < 1024) {
      // Tablet
      maxWidth = 500;
      horizontalPadding = 24;
    } else {
      // Desktop
      maxWidth = 600;
      horizontalPadding = 32;
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: screenWidth < 768
          ? AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF1A2332),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            )
          : null, // No AppBar on web/tablet
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: screenWidth < 768
            ? _buildMobileLayout(isDark, maxWidth, horizontalPadding)
            : _buildWebLayout(isDark),
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark, double maxWidth, double horizontalPadding) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: _buildFormContent(isDark),
        ),
      ),
    );
  }

  Widget _buildWebLayout(bool isDark) {
    return Row(
      children: [
        // Left side - Branding and info
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1A2332),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Brand
                Text(
                  'AgriSynch',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Smart Farming Platform',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                // Features list
                _buildFeature(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Browse Products',
                  description: 'Discover fresh products directly from farmers',
                ),
                const SizedBox(height: 32),
                _buildFeature(
                  icon: Icons.location_on_outlined,
                  title: 'Find Local Farmers',
                  description: 'Connect with farmers in your area',
                ),
                const SizedBox(height: 32),
                _buildFeature(
                  icon: Icons.verified_outlined,
                  title: 'Secure & Trusted',
                  description: 'Safe transactions and verified sellers',
                ),
              ],
            ),
          ),
        ),
        // Right side - Form
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 1200 ? 24 : 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join AgriSynch and start shopping fresh',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildFormContent(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  void _showTermsOfServiceDialog() {
    bool hasScrolledToBottom = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final ScrollController scrollController = ScrollController();
            
            scrollController.addListener(() {
              // Check if scrolled to bottom
              if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
                if (!hasScrolledToBottom) {
                  setState(() => hasScrolledToBottom = true);
                }
              }
            });
            
            return Dialog(
              backgroundColor: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DBF73),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'These Terms of Service explain the rules for using our app. By creating an account or using the platform, you agree to these terms.\n\n'
                        '1. Using the App\n\n'
                        'To use the app, you must:\n\n'
                        '• Provide accurate information\n'
                        '• Be at least 18 years old (or have parental consent)\n'
                        '• Use the service legally and responsibly\n\n'
                        'You are responsible for keeping your account and password secure.\n\n'
                        '2. Ordering and Deliveries\n\n'
                        'Prices, availability, and delivery times may vary depending on the farm.\n\n'
                        'We are not responsible for delays caused by partner farms, weather, or other outside factors.\n\n'
                        'Cancellation and refund policies depend on the farm\'s rules and the status of your order.\n\n'
                        '3. Role of the App\n\n'
                        'The app acts as a platform that connects buyers to farms. We do not own any of the products sold and are not responsible for:\n\n'
                        '• Product quality\n'
                        '• Delivery errors\n'
                        '• Farm-side issues or disputes\n\n'
                        'However, we may assist in communication between both sides when needed.\n\n'
                        '4. Prohibited Activities\n\n'
                        'Users may not:\n\n'
                        '• Provide false information\n'
                        '• Harass or abuse others\n'
                        '• Attempt to hack, disrupt, or misuse the system\n'
                        '• Use the app for illegal transactions\n\n'
                        '5. Limitation of Liability\n\n'
                        'We are not liable for:\n\n'
                        '• Losses caused by incorrect user information\n'
                        '• Delivery delays or product issues\n'
                        '• Technical issues such as downtime, bugs, or errors\n\n'
                        'Use the app at your own discretion and risk.\n\n'
                        '6. Termination of Accounts\n\n'
                        'We may suspend or remove accounts that:\n\n'
                        '• Violate these terms\n'
                        '• Abuse the platform\n'
                        '• Engage in suspicious or harmful activities\n\n'
                        'Users may delete their own accounts at any time.\n\n'
                        '7. Changes to the Terms\n\n'
                        'We may update these Terms of Service when necessary. A notice will be provided within the app when significant changes occur.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE0E0E0),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  
                  // Footer with Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF37474F)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasScrolledToBottom)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.info, color: Color(0xFFFF9800), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Scroll to the bottom to agree',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(
                                    color: Color(0xFFB0BEC5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: hasScrolledToBottom
                                    ? () {
                                        this.setState(() => _acceptedTerms = true);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1DBF73),
                                  disabledBackgroundColor: const Color(0xFF37474F),
                                ),
                                child: Text(
                                  'Agree',
                                  style: TextStyle(
                                    color: hasScrolledToBottom ? Colors.white : const Color(0xFFB0BEC5),
                                    fontSize: 14,
                                  ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    // Account Type - Buyer only for new registrations
                    // (Existing farmer accounts are preserved in database)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A34),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1DBF73)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.shopping_cart, color: Color(0xFF1DBF73)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Type: Buyer',
                                    style: TextStyle(
                                      color: Color(0xFF1DBF73),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Browse products from farmers',
                                    style: TextStyle(
                                      color: Color(0xFF64B5A6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Basic Info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModernTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'John',
                        validator: InputValidator.validateName,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildModernTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Doe',
                        validator: InputValidator.validateName,
                      ),
                    ),

                    // Contact Info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Contact Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModernTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'your@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: InputValidator.validateEmail,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildModernTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+63 9xx xxx xxxx',
                        keyboardType: TextInputType.phone,
                        validator: InputValidator.validatePhone,
                      ),
                    ),

                    // Location Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Delivery Location',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: _openGoogleLocationPicker,
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        label: Text(
                          _selectedAddress != null ? 'Change Location' : 'Select Location on Map',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DBF73),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),

                    if (_selectedAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Password Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Security',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModernTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'At least 8 characters',
                        obscureText: !_isPasswordVisible,
                        validator: InputValidator.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildModernTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        obscureText: !_isConfirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                        ),
                      ),
                    ),

                    // Terms Checkbox
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              // Don't allow direct checkbox interaction
                              // User must read terms through the dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please click the text to read and agree to the terms'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFFFF9800),
                                ),
                              );
                            },
                            checkColor: Colors.white,
                            activeColor: const Color(0xFF1DBF73),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsOfServiceDialog(),
                              child: Text(
                                'I agree to Terms & Privacy Policy',
                                style: const TextStyle(
                                  color: Color(0xFF1DBF73),
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF1DBF73),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sign Up Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DBF73),
                          disabledBackgroundColor: const Color(0xFF555B62),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: const TextStyle(
                              color: Color(0xFFB0BEC5),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: Color(0xFF1DBF73),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            );
          }
        }