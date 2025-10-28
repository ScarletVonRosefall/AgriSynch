import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      return result;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
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
    String? bio,
    String? location,
    String? profileImage,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updateData = {};

        if (name != null) {
          updateData['name'] = name;
          await user.updateDisplayName(name);
        }
        if (nickname != null) updateData['nickname'] = nickname;
        if (bio != null) updateData['bio'] = bio;
        if (location != null) updateData['location'] = location;
        if (profileImage != null) updateData['profileImage'] = profileImage;

        updateData['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore.collection('users').doc(user.uid).update(updateData);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user profile: $e');
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
}
