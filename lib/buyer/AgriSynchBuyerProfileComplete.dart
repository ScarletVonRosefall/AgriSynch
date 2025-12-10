import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../auth/auth_service.dart';
import '../services/validation_service.dart';
import '../shared/theme_helper.dart';
import '../shared/google_location_picker.dart';

class AgriSynchBuyerProfileComplete extends StatefulWidget {
  final bool isRequired;

  const AgriSynchBuyerProfileComplete({super.key, this.isRequired = false});

  @override
  State<AgriSynchBuyerProfileComplete> createState() =>
      _AgriSynchBuyerProfileCompleteState();
}

class _AgriSynchBuyerProfileCompleteState
    extends State<AgriSynchBuyerProfileComplete>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  String? _profileImageBase64;
  bool _isLoading = false;
  bool _isSubmitting = false;
  final _themeNotifier = ThemeNotifier();

  // Buyer-specific preferences
  bool _acceptsNotifications = true;
  String _preferredPaymentMethod = 'Cash';
  List<String> _dietaryPreferences = [];

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
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadProfileData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userData = await AuthService.getUserData();

      if (userData != null && userData.exists) {
        final data = userData.data() as Map<String, dynamic>;

        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _locationController.text = data['location'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _profileImageBase64 = data['profileImage'];
          _acceptsNotifications = data['acceptsNotifications'] ?? true;
          _preferredPaymentMethod = data['preferredPaymentMethod'] ?? 'Cash';
          _dietaryPreferences =
              List<String>.from(data['dietaryPreferences'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() => _profileImageBase64 = base64String);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo updated'),
              backgroundColor: Color(0xFF1DBF73),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    // Validate required fields
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name');
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('Please enter your last name');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter your location');
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      _showError('Please enter a brief bio about yourself');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      final success = await AuthService.updateUserProfile(
        name: fullName,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: _profileImageBase64,
        profileComplete: true,
      );

      // Save buyer-specific preferences to Firestore
      if (success) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'acceptsNotifications': _acceptsNotifications,
              'preferredPaymentMethod': _preferredPaymentMethod,
              'dietaryPreferences': _dietaryPreferences,
              'userType': 'buyer',
            });
          }
        } catch (e) {
          debugPrint('Error saving buyer preferences: $e');
        }
      }

      if (!success) {
        _showError('Failed to save profile. Please try again.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Color(0xFF1DBF73),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home if this was required
        if (widget.isRequired) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DBF73),
                ),
              )
            : isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel with gradient and benefits
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
                  const Text(
                    'Complete Your Buyer Profile',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1DBF73),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBenefitItem(
                    icon: Icons.shopping_bag,
                    title: 'Browse Products',
                    description: 'Find fresh produce from local farmers',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.local_shipping,
                    title: 'Fast Delivery',
                    description: 'Quick and reliable delivery to your location',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.verified_user,
                    title: 'Secure Payments',
                    description: 'Multiple payment methods for your convenience',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.chat,
                    title: 'Direct Messaging',
                    description: 'Chat with farmers for product information',
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right panel with form
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildProfileForm(),
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
              'Complete Your Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us get to know you better as a buyer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFFB0BEC5),
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Photo
        Center(
          child: Column(
            children: [
              _buildProfileImage(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DBF73),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Personal Information Section
        _buildSectionTitle('Personal Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.person_outline,
          hintText: 'Enter your first name',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          icon: Icons.person_outline,
          hintText: 'Enter your last name',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          hintText: '+63 9XX XXX XXXX',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        // Location Section
        _buildSectionTitle('Location & Delivery'),
        const SizedBox(height: 16),
        _buildLocationField(),
        const SizedBox(height: 24),
        // Bio Section
        _buildSectionTitle('About You'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.edit_outlined,
          hintText: 'Tell us a bit about yourself (50-200 characters)',
          maxLines: 3,
          maxLength: 200,
        ),
        const SizedBox(height: 24),
        // Buyer Preferences Section
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 16),
        _buildPreferenceCard(),
        const SizedBox(height: 24),
        // Submit Button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveProfile,
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
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1DBF73),
          width: 3,
        ),
        image: _profileImageBase64 != null
            ? DecorationImage(
                image: MemoryImage(base64Decode(_profileImageBase64!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _profileImageBase64 == null
          ? const Icon(
              Icons.person,
              size: 60,
              color: Color(0xFF1DBF73),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1DBF73),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF90A4AE),
              fontFamily: 'Poppins',
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1DBF73),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2332),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF37474F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF37474F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1DBF73), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            counterStyle: const TextStyle(
              color: Color(0xFF90A4AE),
              fontFamily: 'Poppins',
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Tap button to get location',
                  hintStyle: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF1DBF73),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF37474F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF37474F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1DBF73), width: 2),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1DBF73),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () async {
                  try {
                    final result = await Navigator.push<LocationPickerResult>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoogleLocationPickerPage(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _locationController.text = result.address;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location selected'),
                            backgroundColor: Color(0xFF1DBF73),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    _showError('Error getting location: $e');
                  }
                },
                icon: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF37474F),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method
          const Text(
            'Preferred Payment Method',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF37474F)),
              color: const Color(0xFF0F172A),
            ),
            child: DropdownButton<String>(
              value: _preferredPaymentMethod,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: const Color(0xFF1A2332),
              items: ['Cash', 'GCash', 'Bank Transfer', 'Installment']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            method,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _preferredPaymentMethod = value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          // Notifications Preference
          Row(
            children: [
              Checkbox(
                value: _acceptsNotifications,
                onChanged: (value) {
                  setState(() => _acceptsNotifications = value ?? true);
                },
                activeColor: const Color(0xFF1DBF73),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Accept Notifications',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Get updates on new products and orders',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
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
}
