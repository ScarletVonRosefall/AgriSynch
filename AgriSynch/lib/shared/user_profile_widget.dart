import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../auth/auth_service.dart';
import 'theme_helper.dart';

class UserProfileWidget extends StatefulWidget {
  final bool showEmail;
  final bool showLocation;
  final double imageSize;
  final bool showEditButton;

  const UserProfileWidget({
    super.key,
    this.showEmail = true,
    this.showLocation = false,
    this.imageSize = 60,
    this.showEditButton = false,
  });

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  final _storage = const FlutterSecureStorage();
  String _name = '';
  String _nickname = '';
  String _email = '';
  String _location = '';
  String? _profileImageBase64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Public method to refresh profile data
  Future<void> refreshProfile() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get email from Firebase Auth (source of truth)
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? '';
      
      // Try to load from Firebase first
      final userData = await AuthService.getUserData();

      if (userData != null && userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _name = data['name'] ?? data['nickname'] ?? 'User';
            _nickname = data['nickname'] ?? '';
            _email = userEmail; // Always use Firebase Auth email
            _location = data['location'] ?? '';
            _profileImageBase64 = data['profileImage'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        // Fallback to local storage for offline capability
        String name = await _storage.read(key: 'user_name') ?? '';
        if (name.isEmpty) {
          name = await _storage.read(key: 'name') ?? 'User';
        }
        
        final nickname = await _storage.read(key: 'user_nickname') ?? '';
        final location = await _storage.read(key: 'user_location') ?? '';
        final profileImage = await _storage.read(key: 'profile_image');

        if (mounted) {
          setState(() {
            _name = name.isEmpty ? 'User' : name;
            _nickname = nickname;
            _email = userEmail; // Always use Firebase Auth email
            _location = location;
            _profileImageBase64 = profileImage;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = 'User';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: _profileImageBase64 != null && _profileImageBase64!.isNotEmpty
          ? ClipOval(
              child: Image.memory(
                base64Decode(_profileImageBase64!),
                width: widget.imageSize,
                height: widget.imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ClipOval(
                    child: Image.asset(
                      'assets/AgriSynchLogoNB2.png',
                      width: widget.imageSize,
                      height: widget.imageSize,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            )
          : ClipOval(
              child: Image.asset(
                'assets/AgriSynchLogoNB2.png',
                width: widget.imageSize,
                height: widget.imageSize,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeNotifier().isDarkMode;
    
    if (_isLoading) {
      return Row(
        children: [
          Container(
            width: widget.imageSize,
            height: widget.imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (widget.showEmail) ...[
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildProfileImage(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_nickname.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _nickname,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.showEmail && _email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.showLocation && _location.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _location,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (widget.showEditButton) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ],
    );
  }
}

// Quick profile header widget for drawer/app bars
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
        ),
      ),
      child: const UserProfileWidget(
        showEmail: true,
        showLocation: true,
        imageSize: 70,
        showEditButton: true,
      ),
    );
  }
}
