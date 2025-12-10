import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../auth/auth_service.dart';
import '../shared/theme_helper.dart';
import '../shared/google_location_picker.dart';

class AgriSynchBuyerProfileWeb extends StatefulWidget {
  final bool isRequired;

  const AgriSynchBuyerProfileWeb({super.key, this.isRequired = false});

  @override
  State<AgriSynchBuyerProfileWeb> createState() =>
      _AgriSynchBuyerProfileWebState();
}

class _AgriSynchBuyerProfileWebState extends State<AgriSynchBuyerProfileWeb>
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
              content: Text('Photo updated successfully'),
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
      _showError('Please tell us about yourself');
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
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2332),
          ),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2332)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DBF73),
                ),
              )
            : isDesktop
                ? _buildWebLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              // Main card with left photo + right form
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0E7FF),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Photo
                    Container(
                      width: 280,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        border: Border(
                          right: BorderSide(
                            color: const Color(0xFFE0E7FF),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile photo
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1DBF73),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1DBF73)
                                      .withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _profileImageBase64 != null
                                  ? DecorationImage(
                                      image: MemoryImage(
                                          base64Decode(_profileImageBase64!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageBase64 == null
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF1DBF73)
                                              .withOpacity(0.1),
                                          const Color(0xFF1DBF73)
                                              .withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Color(0xFF1DBF73),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 24),
                          // Upload button
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Upload Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DBF73),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Delete button
                          if (_profileImageBase64 != null)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _profileImageBase64 = null);
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right side - Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2332),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Help us know you better',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // First and Last Name
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _firstNameController,
                                    label: 'Your First Name',
                                    icon: Icons.person_outline,
                                    hintText: 'Juan',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _lastNameController,
                                    label: 'Your Last Name',
                                    icon: Icons.person_outline,
                                    hintText: 'Dela Cruz',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Phone
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              hintText: '+63 9XX XXX XXXX',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            // Location
                            _buildLocationField(),
                            const SizedBox(height: 20),
                            // Bio
                            _buildTextField(
                              controller: _bioController,
                              label: 'Your Bio',
                              icon: Icons.edit_outlined,
                              hintText: 'Fresh food enthusiast from Nueva Ecija',
                              maxLines: 3,
                              maxLength: 200,
                            ),
                            const SizedBox(height: 24),
                            // Preferences section
                            const Divider(height: 32),
                            const SizedBox(height: 8),
                            const Text(
                              'Preferences',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2332),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPreferenceCard(),
                            const SizedBox(height: 32),
                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1DBF73),
                                  disabledBackgroundColor:
                                      const Color(0xFF90A4AE),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
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
                                        'COMPLETE YOUR PROFILE',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          // Profile photo section
          Center(
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1DBF73),
                      width: 4,
                    ),
                    image: _profileImageBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(_profileImageBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImageBase64 == null
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1DBF73).withOpacity(0.1),
                                const Color(0xFF1DBF73).withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF1DBF73),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DBF73),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Personal information card
          _buildCard(
            title: 'Personal Information',
            subtitle: 'Help us know you better',
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                hintText: 'Juan',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                hintText: 'Dela Cruz',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                hintText: '+63 9XX XXX XXXX',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location card
          _buildCard(
            title: 'Location & Delivery',
            subtitle: 'Where should we deliver?',
            children: [
              _buildLocationField(),
            ],
          ),
          const SizedBox(height: 16),
          // About you card
          _buildCard(
            title: 'About You',
            subtitle: 'Tell us about yourself',
            children: [
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.edit_outlined,
                hintText: 'Fresh food enthusiast...',
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preferences card
          _buildCard(
            title: 'Preferences',
            subtitle: 'Customize your experience',
            children: [
              _buildPreferenceCard(),
            ],
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DBF73),
                disabledBackgroundColor: const Color(0xFF90A4AE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1DBF73).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1DBF73).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1DBF73),
            ),
            child: const Center(
              child: Text(
                '✓',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete your profile to unlock all features',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF1DBF73),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E7FF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2332),
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
              color: Color(0xFF94A3B8),
              fontFamily: 'Poppins',
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1DBF73),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF1DBF73), width: 2),
            ),
            counterStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF1A2332),
            fontFamily: 'Poppins',
            fontSize: 14,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2332),
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
                  hintText: 'Tap button to select location',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF1DBF73),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF1DBF73), width: 2),
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF1A2332),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1DBF73),
                borderRadius: BorderRadius.circular(8),
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
                  size: 20,
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: _preferredPaymentMethod,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: Colors.white,
              items: ['Cash', 'GCash', 'Bank Transfer', 'Installment']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            method,
                            style: const TextStyle(
                              color: Color(0xFF1A2332),
                              fontFamily: 'Poppins',
                              fontSize: 14,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2332),
                        ),
                      ),
                      Text(
                        'Get updates on orders and new products',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
