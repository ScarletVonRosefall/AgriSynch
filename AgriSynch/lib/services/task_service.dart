import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Reference to user's tasks collection
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }
    print('Current user ID: $userId');
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
    
    print('Creating task in users/$currentUserId/tasks/');
    
    await _tasksCollection.add({
      'alarmCount': 0,
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'pending',
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'completedAt': null,
      'category': category,
      'fieldLocation': fieldLocation,
      'cropType': cropType,
      'assignedTo': assignedTo,
      'estimatedDuration': estimatedDuration,
      'weatherDependent': weatherDependent ?? false,
      'completed': false,
      'progress': 0,
      'notes': notes,
      'userId': currentUserId,
      'recurringTask': recurringTask ?? false,
      'recurringFrequency': recurringFrequency,
    });
  }

  // Get all tasks stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getTasks({int limit = 20}) {
    if (currentUserId == null) {
      print('ERROR: No authenticated user in getTasks()');
      // Return an empty stream instead of throwing
      return Stream.fromIterable([]).cast<QuerySnapshot<Map<String, dynamic>>>();
    }
    
    print('Getting tasks for user: $currentUserId');
    
    try {
      // TODO: Restore second orderBy after creating composite index
      // Temporary fix until index is created
      return _tasksCollection
          .orderBy('dueDate')
          .limit(limit)
          .snapshots()
          .handleError((error) {
            print('ERROR in tasks stream: $error');
            // Don't let the stream fail completely
            return Stream.empty();
          });
    } catch (e) {
      print('ERROR setting up tasks stream: $e');
      // Return empty stream on setup failure
      return Stream.fromIterable([]).cast<QuerySnapshot<Map<String, dynamic>>>();
    }
  }

  // Get pending tasks stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingTasks() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _tasksCollection
        .where('completed', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots();
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    print('=== Task Update Process Started ===');
    print('TaskId: $taskId');
    print('Updates: $updates');

    // Create a copy of the updates to avoid concurrent modification
    final updateData = Map<String, dynamic>.from(updates);

    // Set up a timeout for the entire operation
    return Future.any([
      // The main update operation
      _performTaskUpdate(taskId, updateData),
      
      // A timeout that will throw if the update takes too long
      Future.delayed(const Duration(seconds: 10)).then((_) {
        throw TimeoutException('Task update timed out after 10 seconds');
      }),
    ]).catchError((error) {
      print('=== Task Update Error ===');
      print('Error type: ${error.runtimeType}');
      print('Error details: $error');
      
      if (error is TimeoutException) {
        throw Exception('Update timed out. Please try again.');
      }
      throw Exception('Failed to update task: $error');
    });
  }

  Future<void> _performTaskUpdate(String taskId, Map<String, dynamic> updateData) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the task document with timeout
        final taskRef = _tasksCollection.doc(taskId);
        final taskDoc = await transaction.get(taskRef)
            .timeout(const Duration(seconds: 3));

        if (!taskDoc.exists) {
          throw Exception('Task not found');
        }

        // Start with a fresh copy of the current data
        final currentData = taskDoc.data() as Map<String, dynamic>;
        final newData = Map<String, dynamic>.from(currentData);

        // Update timestamp first
        newData['updatedAt'] = FieldValue.serverTimestamp();

        // Basic fields with validation and sanitization
        if (updateData.containsKey('title')) {
          final title = updateData['title']?.toString().trim() ?? '';
          if (title.isEmpty) {
            throw Exception('Task title cannot be empty');
          }
          newData['title'] = title;
        }

        // Description
        if (updateData.containsKey('description')) {
          newData['description'] = updateData['description']?.toString().trim() ?? '';
        }

        // Category with validation
        if (updateData.containsKey('category')) {
          final category = updateData['category']?.toString().trim();
          if (category?.isNotEmpty == true) {
            newData['category'] = category;
          }
        }

        // Priority with validation
        if (updateData.containsKey('priority')) {
          final priority = updateData['priority']?.toString().trim();
          if (['Low', 'Medium', 'High', 'Urgent'].contains(priority)) {
            newData['priority'] = priority;
          } else {
            newData['priority'] = 'Medium';
          }
        }

        // Location
        if (updateData.containsKey('location')) {
          newData['location'] = updateData['location']?.toString().trim() ?? '';
        }

        // Boolean fields
        newData['weatherDependent'] = updateData['weatherDependent'] == true;
        newData['recurringTask'] = updateData['recurringTask'] == true;

        // Recurring frequency
        if (updateData.containsKey('recurringFrequency')) {
          newData['recurringFrequency'] = 
              updateData['recurringFrequency']?.toString().trim() ?? '';
        }

        // Due date with validation
        if (updateData.containsKey('dueDate')) {
          final dueDate = updateData['dueDate'];
          if (dueDate is DateTime) {
            newData['dueDate'] = Timestamp.fromDate(dueDate);
          } else if (dueDate is Timestamp) {
            newData['dueDate'] = dueDate;
          } else {
            throw Exception('Invalid due date format');
          }
        }

        // Duration with validation
        if (updateData.containsKey('estimatedDuration')) {
          final duration = updateData['estimatedDuration'];
          if (duration is num) {
            if (duration <= 0) {
              throw Exception('Duration must be greater than 0');
            }
            newData['estimatedDuration'] = duration.toDouble();
          } else {
            final parsedDuration = double.tryParse(duration.toString());
            if (parsedDuration == null || parsedDuration <= 0) {
              throw Exception('Invalid duration value');
            }
            newData['estimatedDuration'] = parsedDuration;
          }
        }

        // Perform the update
        transaction.set(taskRef, newData);

      }, timeout: const Duration(seconds: 5));

      print('Task update completed successfully');
      print('=== Task Update Process Completed ===');
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Database operation timed out');
      }
      rethrow;
    }
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