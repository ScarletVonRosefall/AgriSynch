import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AgriSynch.dart';
import '../buyer/AgriSynchBuyerHomePage.dart';
import '../shared/profile_page.dart';
import 'auth_service.dart';
import 'AgriSynchLogin.dart';
import 'AgriSynchVerify.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> _getUserRole(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['accountType'] ?? 'Farmer'; // Default to Farmer if not found
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2FDE0),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          );
        }

        // If user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Reload user to get latest verification status (with timeout)
          return FutureBuilder(
            future: user.reload()
                .timeout(const Duration(seconds: 5))
                .then((_) => FirebaseAuth.instance.currentUser)
                .catchError((e) {
                  print('Error reloading user: $e');
                  return user; // Return original user on error
                }),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF2FDE0),
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  ),
                );
              }
              
              final refreshedUser = userSnapshot.data ?? user;
              
              // Check if email is verified
              if (!refreshedUser.emailVerified) {
                return const AgriSynchEmailVerificationPage();
              }
              
              return _buildAuthenticatedView(refreshedUser);
            },
          );
        }

        // If user is not signed in, show login page
        return snapshot.hasError 
          ? _buildErrorScreen(context, snapshot.error.toString())
          : const AgriSynchLoginPage();
      },
    );
  }

  Widget _buildAuthenticatedView(User user) {
    return Builder(
      builder: (context) {
        // Check if profile is complete
        return FutureBuilder<bool>(
          future: AuthService.isProfileComplete(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF2FDE0),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                ),
              );
            }
            
            // If profile is incomplete, force profile completion
            if (profileSnapshot.data == false) {
              return const ProfilePage(isRequired: true);
            }
            
            // If profile is complete, check their role and show appropriate page
            return FutureBuilder<String>(
              future: _getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Navigate based on user role
                if (roleSnapshot.data == 'Buyer') {
                  return const AgriSynchBuyerHomePage();
                } else {
                  return const AgriSynchHome(); // Farmer's home
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FDE0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh the page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
