import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }
    debugPrint('Current user ID: $userId');
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

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
    
    debugPrint('Creating task in users/$currentUserId/tasks/');
    
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getTasks({int limit = 20}) {
    if (currentUserId == null) {
      debugPrint('ERROR: No authenticated user in getTasks()');
      return Stream.fromIterable([]).cast<QuerySnapshot<Map<String, dynamic>>>();
    }
    
    debugPrint('Getting tasks for user: $currentUserId');
    
    try {
      // TODO: Restore second orderBy after creating composite index in Firebase Console
      return _tasksCollection
          .orderBy('dueDate')
          .limit(limit)
          .snapshots()
          .handleError((error) {
            debugPrint('ERROR in tasks stream: $error');
            return Stream.empty();
          });
    } catch (e) {
      debugPrint('ERROR setting up tasks stream: $e');
      return Stream.fromIterable([]).cast<QuerySnapshot<Map<String, dynamic>>>();
    }
  }

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

    debugPrint('=== Task Update Process Started ===');
    debugPrint('TaskId: $taskId');
    debugPrint('Updates: $updates');

    final updateData = Map<String, dynamic>.from(updates);

    return Future.any([
      _performTaskUpdate(taskId, updateData),
      
      Future.delayed(const Duration(seconds: 10)).then((_) {
        throw TimeoutException('Task update timed out after 10 seconds');
      }),
    ]).catchError((error) {
      debugPrint('=== Task Update Error ===');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Error details: $error');
      
      if (error is TimeoutException) {
        throw Exception('Update timed out. Please try again.');
      }
      throw Exception('Failed to update task: $error');
    });
  }

  Future<void> _performTaskUpdate(String taskId, Map<String, dynamic> updateData) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final taskRef = _tasksCollection.doc(taskId);
        final taskDoc = await transaction.get(taskRef)
            .timeout(const Duration(seconds: 3));

        if (!taskDoc.exists) {
          throw Exception('Task not found');
        }

        final currentData = taskDoc.data() as Map<String, dynamic>;
        final newData = Map<String, dynamic>.from(currentData);

        newData['updatedAt'] = FieldValue.serverTimestamp();

        if (updateData.containsKey('title')) {
          final title = updateData['title']?.toString().trim() ?? '';
          if (title.isEmpty) {
            throw Exception('Task title cannot be empty');
          }
          newData['title'] = title;
        }

        if (updateData.containsKey('description')) {
          newData['description'] = updateData['description']?.toString().trim() ?? '';
        }

        if (updateData.containsKey('category')) {
          final category = updateData['category']?.toString().trim();
          if (category?.isNotEmpty == true) {
            newData['category'] = category;
          }
        }

        if (updateData.containsKey('priority')) {
          final priority = updateData['priority']?.toString().trim();
          if (['Low', 'Medium', 'High', 'Urgent'].contains(priority)) {
            newData['priority'] = priority;
          } else {
            newData['priority'] = 'Medium';
          }
        }

        if (updateData.containsKey('location')) {
          newData['location'] = updateData['location']?.toString().trim() ?? '';
        }

        newData['weatherDependent'] = updateData['weatherDependent'] == true;
        newData['recurringTask'] = updateData['recurringTask'] == true;

        if (updateData.containsKey('recurringFrequency')) {
          newData['recurringFrequency'] = 
              updateData['recurringFrequency']?.toString().trim() ?? '';
        }

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

        transaction.set(taskRef, newData);

      }, timeout: const Duration(seconds: 5));

      debugPrint('Task update completed successfully');
      debugPrint('=== Task Update Process Completed ===');
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Database operation timed out');
      }
      rethrow;
    }
  }

  Future<void> completeTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).update({
      'completed': true,
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).delete();
  }

  Future<void> updateAlarmCount(String taskId, int alarmCount) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _tasksCollection.doc(taskId).update({
      'alarmCount': alarmCount,
      'updatedAt': Timestamp.now(),
    });
  }

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

  Stream<QuerySnapshot<Map<String, dynamic>>> getTasksByCategory(
      String category) {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _tasksCollection
        .where('category', isEqualTo: category)
        .orderBy('dueDate')
        .snapshots();
  }
}