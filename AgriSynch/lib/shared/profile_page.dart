import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import '../services/validation_service.dart';
import 'theme_helper.dart';
import 'google_location_picker.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final bool isRequired;
  
  const ProfilePage({super.key, this.isRequired = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  final _surnameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  String? _profileImageBase64;
  bool _isEditing = false;
  bool _isLoading = true;
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadProfileData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Get email from Firebase Auth (source of truth)
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? '';
      
      // Try to load from Firebase first
      final userData = await AuthService.getUserData();

      if (userData != null && userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        
        // Check if profile has been set up (has 'name' field)
        final hasProfileSetup = data.containsKey('name') && (data['name'] as String).isNotEmpty;
        
        if (hasProfileSetup) {
          // Load existing profile data
          final fullName = data['name'] ?? '';
          _parseFullName(fullName);
          
          setState(() {
            _nicknameController.text = data['nickname'] ?? '';
            _emailController.text = userEmail;
            _phoneController.text = data['phone'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _locationController.text = data['location'] ?? '';
            _profileImageBase64 = data['profileImage'] ?? '';
            _isLoading = false;
            if (widget.isRequired) {
              _isEditing = true;
            }
          });
        } else {
          // Pre-fill from signup data
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final phone = data['phone'] ?? '';
          final address = data['address'] ?? '';
          
          setState(() {
            _surnameController.text = lastName;
            _firstNameController.text = firstName;
            _middleNameController.text = ''; // Not collected during signup
            _nicknameController.text = ''; // Not collected during signup
            _emailController.text = userEmail;
            _phoneController.text = phone;
            _bioController.text = '';
            _locationController.text = address;
            _profileImageBase64 = '';
            _isLoading = false;
            if (widget.isRequired) {
              _isEditing = true;
            }
          });
        }
      } else {
        // Fallback to local storage for offline capability
        final name = await _storage.read(key: 'user_name') ?? '';
        final nickname = await _storage.read(key: 'user_nickname') ?? '';
        final phone = await _storage.read(key: 'user_phone') ?? '';
        final bio = await _storage.read(key: 'user_bio') ?? '';
        final location = await _storage.read(key: 'user_location') ?? '';
        final profileImage = await _storage.read(key: 'profile_image');

        // Parse the full name into parts
        _parseFullName(name);

        setState(() {
          _nicknameController.text = nickname;
          _emailController.text = userEmail; // Always use Firebase Auth email
          _phoneController.text = phone;
          _bioController.text = bio;
          _locationController.text = location;
          _profileImageBase64 = profileImage;
          _isLoading = false;
          // Auto-enable editing if profile is required
          if (widget.isRequired) {
            _isEditing = true;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  void _parseFullName(String fullName) {
    if (fullName.isEmpty) {
      _surnameController.text = '';
      _firstNameController.text = '';
      _middleNameController.text = '';
      return;
    }

    // Check if name is in "Surname, First Name, Middle Name" format
    if (fullName.contains(',')) {
      final parts = fullName.split(',').map((e) => e.trim()).toList();
      _surnameController.text = parts.isNotEmpty ? parts[0] : '';
      _firstNameController.text = parts.length > 1 ? parts[1] : '';
      _middleNameController.text = parts.length > 2 ? parts[2] : '';
    } else {
      // If no commas, assume space-separated format
      final words = fullName.split(' ').where((w) => w.isNotEmpty).toList();
      _surnameController.text = words.isNotEmpty ? words[0] : '';
      _firstNameController.text = words.length > 1 ? words[1] : '';
      _middleNameController.text = words.length > 2 ? words.sublist(2).join(' ') : '';
    }
  }

  Future<void> _openGoogleLocationPicker() async {
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Location set: ${result.address}')),
              ],
            ),
            backgroundColor: const Color(0xFF1DBF73),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _buildFullName() {
    // Combine the three fields into comma-separated format
    final surname = _surnameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();

    if (surname.isEmpty && firstName.isEmpty && middleName.isEmpty) {
      return '';
    }

    final parts = <String>[];
    if (surname.isNotEmpty) parts.add(surname);
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName.isNotEmpty) parts.add(middleName);

    return parts.join(', ');
  }

  Future<void> _saveProfileData() async {
    // Build full name from three fields
    final fullName = _buildFullName();
    
    // Check if required fields are filled when in required mode
    if (widget.isRequired) {
      final surname = _surnameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final nickname = _nicknameController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final location = _locationController.text.trim();
      
      // Check each field and provide specific error message
      List<String> missingFields = [];
      if (surname.isEmpty) missingFields.add('Surname');
      if (firstName.isEmpty) missingFields.add('First Name');
      if (middleName.isEmpty) missingFields.add('Middle Name');
      if (nickname.isEmpty) missingFields.add('Nickname');
      if (phone.isEmpty) missingFields.add('Phone Number');
      if (bio.isEmpty) missingFields.add('Bio/Description');
      if (location.isEmpty) missingFields.add('Location');
      
      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in: ${missingFields.join(', ')}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }
    
    // Validate inputs before saving
    final nameValidation = ValidationService.validateName(fullName);
    if (nameValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameValidation), backgroundColor: Colors.red),
      );
      return;
    }

    final nicknameValidation = ValidationService.validateNickname(_nicknameController.text);
    if (nicknameValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nicknameValidation), backgroundColor: Colors.red),
      );
      return;
    }

    // Phone validation (optional)
    final phoneValidation = ValidationService.validateOptionalPhoneNumber(_phoneController.text);
    if (phoneValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneValidation), backgroundColor: Colors.red),
      );
      return;
    }

    final bioValidation = ValidationService.validateOptionalDescription(_bioController.text);
    if (bioValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bioValidation), backgroundColor: Colors.red),
      );
      return;
    }

    final locationValidation = ValidationService.validateLocation(_locationController.text);
    if (locationValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationValidation), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Check if profile should be marked as complete
      final surname = _surnameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final nickname = _nicknameController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final location = _locationController.text.trim();
      
      // Profile is complete when all fields are filled
      final isComplete = surname.isNotEmpty && firstName.isNotEmpty && middleName.isNotEmpty &&
                         nickname.isNotEmpty && phone.isNotEmpty && bio.isNotEmpty && location.isNotEmpty;
      
      // Save to Firebase first
      final success = await AuthService.updateUserProfile(
        name: ValidationService.sanitizeInput(fullName),
        nickname: ValidationService.sanitizeInput(_nicknameController.text),
        phone: ValidationService.sanitizeInput(_phoneController.text),
        bio: ValidationService.sanitizeInput(_bioController.text),
        location: ValidationService.sanitizeInput(_locationController.text),
        profileImage: _profileImageBase64,
        profileComplete: isComplete,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile to server. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Also save locally for offline capability
      await _storage.write(key: 'user_name', value: ValidationService.sanitizeInput(fullName));
      await _storage.write(
        key: 'user_nickname',
        value: ValidationService.sanitizeInput(_nicknameController.text),
      );
      await _storage.write(
        key: 'user_phone',
        value: ValidationService.sanitizeInput(_phoneController.text),
      );
      // Don't save email to local storage - always get from Firebase Auth
      await _storage.write(key: 'user_bio', value: ValidationService.sanitizeInput(_bioController.text));
      await _storage.write(
        key: 'user_location',
        value: ValidationService.sanitizeInput(_locationController.text),
      );

      if (_profileImageBase64 != null) {
        await _storage.write(key: 'profile_image', value: _profileImageBase64!);
      }

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        // If this was required profile completion, navigate to home
        if (widget.isRequired && isComplete) {
          // Small delay to show the success message
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
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

        setState(() {
          _profileImageBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF263238),
          border: Border.all(color: const Color(0xFF1DBF73), width: 3),
        ),
        child: ClipOval(
          child: _profileImageBase64 != null && _profileImageBase64!.isNotEmpty
              ? Image.memory(
                  base64Decode(_profileImageBase64!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultImage();
                  },
                )
              : _buildDefaultImage(),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Image.asset(
        'assets/AgriSynchLogoNB-min.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(Icons.person, size: 60, color: Colors.grey[600]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isRequired, // Hide back button if required
          title: Text(widget.isRequired ? 'Complete Your Profile' : 'Profile', style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
          )),
          backgroundColor: const Color(0xFF1A2332),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DBF73)),
          ),
        ),
      );
    }

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isRequired, // Hide back button if required
        title: Text(widget.isRequired ? 'Complete Your Profile' : 'Profile', style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
        )),
        backgroundColor: const Color(0xFF1A2332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing
                ? _saveProfileData
                : () => setState(() => _isEditing = true),
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                _loadProfileData();
                setState(() => _isEditing = false);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Show info message when profile completion is required
            if (widget.isRequired) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Required',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please complete all fields in your profile before continuing.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Profile Image
            Center(
              child: Column(
                children: [
                  _buildProfileImage(),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DBF73),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Profile Fields - Name Section
            const Text(
              'Full Name',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1DBF73),
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Surname',
              controller: _surnameController,
              icon: Icons.person,
              hintText: 'Enter surname',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Only letters and spaces
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'First Name',
              controller: _firstNameController,
              icon: Icons.person_outline,
              hintText: 'Enter first name',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Only letters and spaces
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Middle Name',
              controller: _middleNameController,
              icon: Icons.person_outline,
              hintText: 'Enter middle name',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Only letters and spaces
              ],
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Nickname',
              controller: _nicknameController,
              icon: Icons.badge,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Only letters and spaces
              ],
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              isReadOnly: true, // Email is always read-only
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              hintText: '09171234567',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')), // Only numbers and plus sign
                LengthLimitingTextInputFormatter(13), // Maximum 13 characters (for +63 format or 11-digit local)
              ],
            ),
            const SizedBox(height: 20),
            // Location Section - matches signup style
            if (_isEditing) ...[
              const Text(
                'Location',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB0BEC5),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGoogleLocationPicker,
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: Text(
                    _locationController.text.isNotEmpty ? 'Change Location' : 'Select Location on Map',
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
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
              if (_locationController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DBF73).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1DBF73)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF1DBF73)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationController.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              _buildProfileField(
                label: 'Location',
                controller: _locationController,
                icon: Icons.location_on,
                hintText: 'Farm location, city, region',
              ),
            ],
            const SizedBox(height: 20),
            _buildBioField(),
            const SizedBox(height: 40),
            if (!_isEditing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF263238),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF37474F), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Info',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1DBF73),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the edit button to update your profile information.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    
    // Wrap with PopScope to prevent back navigation when profile completion is required
    if (widget.isRequired) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          
          // Show message that profile must be completed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile before continuing'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        child: scaffold,
      );
    }
    
    return scaffold;
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    bool isReadOnly = false, // New parameter for read-only fields
    List<TextInputFormatter>? inputFormatters, // Add input formatters parameter
  }) {
    final bool isFieldEnabled = isReadOnly ? false : _isEditing;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFB0BEC5),
              ),
            ),
            if (isReadOnly) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReadOnly 
                  ? const Color(0xFF37474F)
                  : (_isEditing ? const Color(0xFF1DBF73) : const Color(0xFF37474F)),
              width: 1.5,
            ),
            color: isReadOnly ? const Color(0xFF1A1F2E) : const Color(0xFF263238),
          ),
          child: TextFormField(
            controller: controller,
            enabled: isFieldEnabled,
            readOnly: isReadOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters, // Apply input formatters
            style: TextStyle(
              fontFamily: 'Poppins', 
              fontSize: 16,
              color: isReadOnly ? const Color(0xFF78909C) : const Color(0xFFE0E0E0),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isReadOnly 
                    ? const Color(0xFF78909C)
                    : (_isEditing ? const Color(0xFF1DBF73) : const Color(0xFF78909C)),
              ),
              suffixIcon: isReadOnly 
                  ? Tooltip(
                      message: 'Email cannot be changed',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: const Color(0xFF78909C),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: _isEditing && !isReadOnly ? (hintText ?? 'Enter $label') : '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bio/Description',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFFB0BEC5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? const Color(0xFF1DBF73) : const Color(0xFF37474F),
              width: 1.5,
            ),
            color: const Color(0xFF263238),
          ),
          child: TextFormField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'Poppins', 
              fontSize: 16,
              color: Color(0xFFE0E0E0),
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(
                  Icons.description,
                  color: _isEditing
                      ? const Color(0xFF1DBF73)
                      : const Color(0xFF78909C),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: _isEditing
                  ? 'Tell others about your farming experience, crops, specialties...'
                  : '',
              hintStyle: const TextStyle(
                color: Color(0xFF78909C),
              ),
              hintMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}
