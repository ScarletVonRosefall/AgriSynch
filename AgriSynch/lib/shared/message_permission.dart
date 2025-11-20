import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Returns true if the current user is allowed to initiate or open a chat with [otherUserId].
/// Rule: Admin accounts may message anyone. Farmers/Buyers may NOT message Admins.
Future<bool> canMessageUser(String otherUserId) async {
  final current = FirebaseAuth.instance.currentUser;
  if (current == null) return false;

  try {
    final curDoc = await FirebaseFirestore.instance.collection('users').doc(current.uid).get();
    final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();

    final curRole = (curDoc.data()?['accountType'] ?? curDoc.data()?['userType'] ?? '')
        .toString()
        .toLowerCase();
    final otherRole = (otherDoc.data()?['accountType'] ?? otherDoc.data()?['userType'] ?? '')
        .toString()
        .toLowerCase();

    final curIsAdmin = curRole.contains('admin');
    final otherIsAdmin = otherRole.contains('admin');

    if (otherIsAdmin && !curIsAdmin) return false;
    return true;
  } catch (e) {
    // Conservative: deny if error
    return false;
  }
}
