import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String reportType; // 'product' or 'user'
  final String reportedItemId; // productId or userId
  final String reportedItemName; // product name or user name
  final String category; // Inappropriate Content, Spam, Fraud, etc.
  final String description;
  final String status; // pending, reviewed, resolved, dismissed
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? resolvedBy;

  Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.reportType,
    required this.reportedItemId,
    required this.reportedItemName,
    required this.category,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
    this.resolvedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reportType': reportType,
      'reportedItemId': reportedItemId,
      'reportedItemName': reportedItemName,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
    };
  }

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      reportType: data['reportType'] ?? '',
      reportedItemId: data['reportedItemId'] ?? '',
      reportedItemName: data['reportedItemName'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      resolvedBy: data['resolvedBy'],
    );
  }
}
