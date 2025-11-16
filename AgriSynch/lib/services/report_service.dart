import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Submit a new report
  Future<void> submitReport({
    required String reportType,
    required String reportedItemId,
    required String reportedItemName,
    required String category,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to submit a report');
    }

    // Prevent users from reporting themselves
    if (reportType == 'user' && currentUser.uid == reportedItemId) {
      throw Exception('You cannot report yourself');
    }

    // Get user details
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'Unknown User';
    final userEmail = userData?['email'] ?? currentUser.email ?? '';

    final reportId = DateTime.now().millisecondsSinceEpoch.toString();
    final report = Report(
      id: reportId,
      reporterId: currentUser.uid,
      reporterName: userName,
      reporterEmail: userEmail,
      reportType: reportType,
      reportedItemId: reportedItemId,
      reportedItemName: reportedItemName,
      category: category,
      description: description,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('reports').doc(reportId).set(report.toFirestore());
  }

  /// Get all reports (admin only)
  Stream<List<Report>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit to prevent index issues
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  /// Get reports by status
  Stream<List<Report>> getReportsByStatus(String status) {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: status)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort in memory
      return reports;
    });
  }

  /// Get reports by type
  Stream<List<Report>> getReportsByType(String reportType) {
    return _firestore
        .collection('reports')
        .where('reportType', isEqualTo: reportType)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort in memory
      return reports;
    });
  }

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Admin must be logged in');
    }

    final updateData = {
      'status': status,
      'resolvedAt': status == 'resolved' || status == 'dismissed'
          ? FieldValue.serverTimestamp()
          : null,
      'resolvedBy': currentUser.uid,
    };

    if (adminNotes != null && adminNotes.isNotEmpty) {
      updateData['adminNotes'] = adminNotes;
    }

    await _firestore.collection('reports').doc(reportId).update(updateData);
  }

  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }

  /// Get count of pending reports
  Future<int> getPendingReportsCount() async {
    final snapshot = await _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }
}
