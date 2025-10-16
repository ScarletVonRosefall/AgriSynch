import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AgriSynch.dart';
import 'AgriSynchSignUp.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

        // If user is signed in, show the main app
        if (snapshot.hasData && snapshot.data != null) {
          return const AgriSynchHome();
        }

        // If user is not signed in, show sign up page
        return const AgriSynchSignUpPage();
      },
    );
  }
}