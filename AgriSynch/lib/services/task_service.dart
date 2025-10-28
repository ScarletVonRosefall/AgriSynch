import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Reference to user's tasks collection
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final userId = _auth.currentUser?.uid;
    print('Current user ID: $userId'); // Debug print
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Create a new task
  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    String? category,
    String? fieldLocation,
    String? cropType,
    String? assignedTo,
    double? estimatedDuration,
    bool? weatherDependent,
    bool? recurringTask,
    String? recurringFrequency,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('Creating task in users/$currentUserId/tasks/'); // Debug print
    
    await _tasksCollection.add({
      'alarmCount': 0, // Initialize alarmCount for new tasks
      // Basic Task Info
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'pending',
      
      // Timing
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'completedAt': null,
      
      // Agricultural Specific
      'category': category,
      'fieldLocation': fieldLocation,
      'cropType': cropType,
      
      // Task Management
      'assignedTo': assignedTo,
      'estimatedDuration': estimatedDuration,
      'weatherDependent': weatherDependent ?? false,
      
      // Progress Tracking
      'completed': false,
      'progress': 0,
      'notes': notes,
      
      // Metadata
      'userId': currentUserId,
      'recurringTask': recurringTask ?? false,
      'recurringFrequency': recurringFrequency,
    });
  }

  // Get all tasks stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getTasks() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _tasksCollection
        .orderBy('dueDate')
        .orderBy('priority')
        .snapshots();
  }

  // Get pending tasks stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingTasks() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _tasksCollection
        .where('completed', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots();
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    updates['updatedAt'] = Timestamp.now();
    await _tasksCollection.doc(taskId).update(updates);
  }

  // Mark task as complete
  Future<void> completeTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).update({
      'completed': true,
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).delete();
  }

  // Update alarm count
  Future<void> updateAlarmCount(String taskId, int alarmCount) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).update({
      'alarmCount': alarmCount,
      'updatedAt': Timestamp.now(),
    });
  }

  // Get tasks due today
  Stream<QuerySnapshot<Map<String, dynamic>>> getTasksDueToday() {
    if (currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _tasksCollection
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dueDate')
        .snapshots();
  }

  // Get tasks by category
  Stream<QuerySnapshot<Map<String, dynamic>>> getTasksByCategory(
      String category) {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _tasksCollection
        .where('category', isEqualTo: category)
        .orderBy('dueDate')
        .snapshots();
  }
}