import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/input_validator.dart';
import '../services/rate_limit_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase Auth settings
  static Future<void> initializeAuth() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String userType, // 'farmer' or 'buyer'
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'userType': userType,
          'profileImage': '',
          'nickname': '',
          'bio': '',
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update display name
        await result.user!.updateDisplayName(name);
        // Send verification email
        await result.user!.sendEmailVerification();
      }

      return result;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ensure user document exists in Firestore
      if (result.user != null) {
        await _ensureUserDocumentExists(result.user!);
      }
      
      return result;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Ensure user document exists in Firestore (create if missing)
  static Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        print('⚠️ User document missing for ${user.email}. Creating default document...');
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'userType': 'farmer', // Default type
          'profileImage': '',
          'nickname': '',
          'bio': '',
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created for ${user.email}');
      }
    } catch (e) {
      print('❌ Error ensuring user document exists: $e');
    }
  }

  // Sign out and clear all cached user data
  static Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Clear all local storage to prevent data leakage between accounts
      final storage = const FlutterSecureStorage();
      await storage.deleteAll();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('✅ Signed out and cleared all local data');
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Send password reset email
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Send email verification
  static Future<bool> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending email verification: $e');
      return false;
    }
  }

  // Re-authenticate user
  static Future<bool> reauthenticateUser(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Error during reauthentication: ${e.code} - ${e.message}');
      return false;
    }
  }

  // Update password with current password verification
  static Future<Map<String, dynamic>> updatePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // First re-authenticate
        bool reauthed = await reauthenticateUser(currentPassword);
        if (!reauthed) {
          return {
            'success': false,
            'message': 'Current password is incorrect'
          };
        }
        
        // Then update password
        await user.updatePassword(newPassword);
        return {
          'success': true,
          'message': 'Password updated successfully'
        };
      }
      return {
        'success': false,
        'message': 'No user logged in'
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The new password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log in again before changing your password';
          break;
        default:
          message = e.message ?? 'Failed to update password';
      }
      return {
        'success': false,
        'message': message
      };
    }
  }

  // Get user data from Firestore
  static Future<DocumentSnapshot?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return await _firestore.collection('users').doc(user.uid).get();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile in Firestore
  static Future<bool> updateUserProfile({
    String? name,
    String? nickname,
    String? phone,
    String? bio,
    String? location,
    String? profileImage,
    bool? profileComplete,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ Error: No user logged in');
        return false;
      }

      // Sanitize all text inputs before saving to database
      final sanitizedName = name != null ? InputValidator.sanitizeName(name) : null;
      final sanitizedNickname = nickname != null ? InputValidator.sanitizeName(nickname) : null;
      final sanitizedPhone = phone != null ? phone.trim() : null;
      final sanitizedBio = bio != null ? InputValidator.sanitizeDescription(bio, maxLength: 500) : null;
      final sanitizedLocation = location != null ? InputValidator.sanitizeAddress(location) : null;

      // Validate sanitized inputs
      if (sanitizedName != null && sanitizedName.isEmpty && name!.isNotEmpty) {
        print('❌ Error: Name contains invalid characters');
        return false;
      }

      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      Map<String, dynamic> updateData = {};

      if (sanitizedName != null) {
        updateData['name'] = sanitizedName;
        await user.updateDisplayName(sanitizedName);
      }
      if (sanitizedNickname != null) updateData['nickname'] = sanitizedNickname;
      if (sanitizedPhone != null) updateData['phone'] = sanitizedPhone;
      if (sanitizedBio != null) updateData['bio'] = sanitizedBio;
      if (sanitizedLocation != null) updateData['location'] = sanitizedLocation;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      if (profileComplete != null) updateData['profileComplete'] = profileComplete;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      if (!userDoc.exists) {
        // Create document if it doesn't exist
        print('⚠️ User document does not exist for ${user.uid}. Creating it now...');
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'userType': 'farmer', // Default, should be updated if known
          'createdAt': FieldValue.serverTimestamp(),
          ...updateData,
        });
        print('✅ User document created for ${user.email}');
      } else {
        // Update existing document
        await _firestore.collection('users').doc(user.uid).update(updateData);
        print('✅ Profile updated for ${user.email}');
      }
      
      return true;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      print('   User: ${_auth.currentUser?.email}');
      print('   UID: ${_auth.currentUser?.uid}');
      return false;
    }
  }

  // Get user type (farmer or buyer)
  static Future<String?> getUserType() async {
    try {
      DocumentSnapshot? doc = await getUserData();
      if (doc != null && doc.exists) {
        return doc.get('userType') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user to get updated email verification status
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if user has completed their profile
  // Required fields: surname, firstName, middleName, nickname, phone, bio, location
  static Future<bool> isProfileComplete() async {
    try {
      DocumentSnapshot? doc = await getUserData();
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        
        // Check if profileComplete flag is explicitly set
        if (data?['profileComplete'] == true) {
          return true;
        }
        
        // Fallback: check if required fields are filled
        final name = data?['name'] as String? ?? '';
        final nickname = data?['nickname'] as String? ?? '';
        final phone = data?['phone'] as String? ?? '';
        final bio = data?['bio'] as String? ?? '';
        final location = data?['location'] as String? ?? '';
        
        // Parse name to check for surname, first name, and middle name
        final nameParts = name.split(',').map((e) => e.trim()).toList();
        bool hasValidName = false;
        
        if (nameParts.length >= 3) {
          // Format: "Surname, FirstName, MiddleName"
          final surname = nameParts[0];
          final firstName = nameParts.length > 1 ? nameParts[1] : '';
          final middleName = nameParts.length > 2 ? nameParts[2] : '';
          hasValidName = surname.isNotEmpty && firstName.isNotEmpty && middleName.isNotEmpty;
        }
        
        // Profile is complete if all fields are filled
        return hasValidName && nickname.isNotEmpty && phone.isNotEmpty && 
               bio.isNotEmpty && location.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  // Check if current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Submit account action request (suspension or deletion)
  static Future<bool> submitAccountActionRequest(String reason, String requestType) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Validate request type
      if (requestType != 'suspension' && requestType != 'deletion') {
        print('❌ Invalid request type: $requestType');
        return false;
      }

      // Check rate limit
      final canRequest = await RateLimitService.checkRateLimit(
        'deletion_request',
        userId: user.uid,
      );
      if (!canRequest) {
        final errorMessage = RateLimitService.getRateLimitMessage('deletion_request');
        print('🚫 AuthService: $errorMessage');
        throw Exception(errorMessage);
      }

      // Get user data for the request
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      // Create account action request
      await _firestore.collection('accountActionRequests').add({
        'userId': user.uid,
        'userName': userData?['name'] ?? 'Unknown User',
        'userEmail': user.email ?? '',
        'requestType': requestType, // 'suspension' or 'deletion'
        'reason': reason,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Account action request submitted: $requestType for user ${user.uid}');
      return true;
    } catch (e) {
      print('❌ Error submitting account action request: $e');
      return false;
    }
  }

  // Legacy method - kept for backwards compatibility
  @deprecated
  static Future<bool> submitDeletionRequest(String reason) async {
    return submitAccountActionRequest(reason, 'deletion');
  }
}
