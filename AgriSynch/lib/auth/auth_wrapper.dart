import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AgriSynch.dart';
import '../buyer/AgriSynchBuyerHomePage.dart';
import 'AgriSynchSignUp.dart';

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

        // If user is signed in, check their role and show appropriate page
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String>(
            future: _getUserRole(snapshot.data!.uid),
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
        }

        // If user is not signed in, show sign up page
        return const AgriSynchSignUpPage();
      },
    );
  }
}
