import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _profileImageBase64;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to load from Firebase first
      final userData = await AuthService.getUserData();
      
      if (userData != null && userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _emailController.text = data['email'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _locationController.text = data['location'] ?? '';
          _profileImageBase64 = data['profileImage'] ?? '';
          _isLoading = false;
        });
      } else {
        // Fallback to local storage for offline capability
        final name = await _storage.read(key: 'user_name') ?? '';
        final nickname = await _storage.read(key: 'user_nickname') ?? '';
        final email = await _storage.read(key: 'user_email') ?? '';
        final bio = await _storage.read(key: 'user_bio') ?? '';
        final location = await _storage.read(key: 'user_location') ?? '';
        final profileImage = await _storage.read(key: 'profile_image');
        
        setState(() {
          _nameController.text = name;
          _nicknameController.text = nickname;
          _emailController.text = email;
          _bioController.text = bio;
          _locationController.text = location;
          _profileImageBase64 = profileImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfileData() async {
    try {
      // Save to Firebase first
      await AuthService.updateUserProfile(
        name: _nameController.text,
        nickname: _nicknameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        profileImage: _profileImageBase64,
      );

      // Also save locally for offline capability
      await _storage.write(key: 'user_name', value: _nameController.text);
      await _storage.write(key: 'user_nickname', value: _nicknameController.text);
      await _storage.write(key: 'user_email', value: _emailController.text);
      await _storage.write(key: 'user_bio', value: _bioController.text);
      await _storage.write(key: 'user_location', value: _locationController.text);
      
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
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
          color: Colors.grey[200],
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 3,
          ),
        ),
        child: _profileImageBase64 != null
            ? ClipOval(
                child: Image.memory(
                  base64Decode(_profileImageBase64!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.person,
                size: 60,
                color: Colors.grey[600],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveProfileData : () => setState(() => _isEditing = true),
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
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Profile Fields
            _buildProfileField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Nickname',
              controller: _nicknameController,
              icon: Icons.badge,
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              label: 'Location',
              controller: _locationController,
              icon: Icons.location_on,
              hintText: 'Farm location, city, region',
            ),
            const SizedBox(height: 20),
            _buildBioField(),
            const SizedBox(height: 40),
            if (!_isEditing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                    width: 1,
                  ),
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
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the edit button to update your profile information.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey[600],
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
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? const Color(0xFF4CAF50) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: _isEditing ? const Color(0xFF4CAF50) : Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: _isEditing ? (hintText ?? 'Enter $label') : '',
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
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? const Color(0xFF4CAF50) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(
                  Icons.description,
                  color: _isEditing ? const Color(0xFF4CAF50) : Colors.grey[500],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: _isEditing ? 'Tell others about your farming experience, crops, specialties...' : '',
              hintMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}
