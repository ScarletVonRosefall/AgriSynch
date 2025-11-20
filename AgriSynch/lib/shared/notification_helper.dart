import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static const String _notificationsKey = 'notifications';
  static int? _cachedUnreadCount;
  static DateTime? _lastCacheUpdate;

  // Notification types
  static const String taskReminder = 'task_reminder';
  static const String orderUpdate = 'order_update';
  static const String systemNotification = 'system';
  static const String taskDeadline = 'task_deadline';
  static const String accountDeletion = 'account_deletion';

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    return notificationsJson.map((json) {
      return Map<String, dynamic>.from(jsonDecode(json));
    }).toList();
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'data': data ?? {},
    };

    notificationsJson.insert(0, jsonEncode(notification));

    // Keep only last 50 notifications
    if (notificationsJson.length > 50) {
      notificationsJson.removeRange(50, notificationsJson.length);
    }

    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  static Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    for (int i = 0; i < notificationsJson.length; i++) {
      final notification = Map<String, dynamic>.from(
        jsonDecode(notificationsJson[i]),
      );
      if (notification['id'] == notificationId) {
        notification['isRead'] = true;
        notificationsJson[i] = jsonEncode(notification);
        break;
      }
    }

    await prefs.setStringList(_notificationsKey, notificationsJson);
    clearCache(); // Clear cache so count is updated
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    for (int i = 0; i < notificationsJson.length; i++) {
      final notification = Map<String, dynamic>.from(
        jsonDecode(notificationsJson[i]),
      );
      notification['isRead'] = true;
      notificationsJson[i] = jsonEncode(notification);
    }

    await prefs.setStringList(_notificationsKey, notificationsJson);
    clearCache(); // Clear cache so count is updated
  }

  static Future<void> deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    notificationsJson.removeWhere((json) {
      final notification = Map<String, dynamic>.from(jsonDecode(json));
      return notification['id'] == notificationId;
    });

    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  static Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  static Future<int> getUnreadCount() async {
    // Use cached value if it's less than 5 seconds old
    if (_cachedUnreadCount != null && _lastCacheUpdate != null) {
      final now = DateTime.now();
      if (now.difference(_lastCacheUpdate!).inSeconds < 5) {
        return _cachedUnreadCount!;
      }
    }

    try {
      // Get local notifications
      final localNotifications = await getNotifications();
      final localUnread = localNotifications.where((n) => n['isRead'] == false).length;

      // Get Firestore notifications with timeout
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _cachedUnreadCount = localUnread;
        _lastCacheUpdate = DateTime.now();
        return localUnread;
      }

      final firestoreSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get()
          .timeout(
            const Duration(seconds: 3),
              onTimeout: () {
              // If timeout, return cached or empty result
              debugPrint('Firestore notification fetch timed out');
              throw TimeoutException('Firestore timeout');
            },
          );

      final totalCount = localUnread + firestoreSnapshot.docs.length;
      _cachedUnreadCount = totalCount;
      _lastCacheUpdate = DateTime.now();
      return totalCount;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      // Return cached value if available
      if (_cachedUnreadCount != null) {
        return _cachedUnreadCount!;
      }
      // Fallback to local notifications only
      try {
        final notifications = await getNotifications();
        final count = notifications.where((n) => n['isRead'] == false).length;
        _cachedUnreadCount = count;
        _lastCacheUpdate = DateTime.now();
        return count;
      } catch (e2) {
        debugPrint('Error getting local notifications: $e2');
        return 0;
      }
    }
  }

  // Clear cache when notifications are marked as read
  static void clearCache() {
    _cachedUnreadCount = null;
    _lastCacheUpdate = null;
  }

  // Helper method to create task-related notifications
  static Future<void> addTaskNotification({
    required String title,
    required String message,
    required String taskId,
    String type = taskReminder,
  }) async {
    await addNotification(
      title: title,
      message: message,
      type: type,
      data: {'taskId': taskId, 'source': 'tasks'},
    );
  }

  // Helper method to create order-related notifications
  static Future<void> addOrderNotification({
    required String title,
    required String message,
    required String orderId,
    String type = orderUpdate,
  }) async {
    await addNotification(
      title: title,
      message: message,
      type: type,
      data: {'orderId': orderId, 'source': 'orders'},
    );
  }

  // Helper method to check and create deadline notifications
  static Future<void> checkTaskDeadlines() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksData = prefs.getStringList('tasks') ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (String taskJson in tasksData) {
      try {
        final taskData = taskJson.split('|');
        if (taskData.length >= 5) {
          final taskTitle = taskData[0];
          final taskDateStr = taskData[3];
          final taskStatus = taskData[4];

          // Skip completed tasks
          if (taskStatus == 'Completed') continue;

          final taskDate = DateTime.parse(taskDateStr);
          final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);

          // Check if task is due today and not completed
          if (taskDay.isAtSameMomentAs(today)) {
            await addTaskNotification(
              title: 'Task Due Today',
              message: 'Don\'t forget: "$taskTitle" is due today!',
              taskId: taskData.join('|'),
              type: taskDeadline,
            );
          }
          // Check if task is overdue
          else if (taskDay.isBefore(today)) {
            final daysOverdue = today.difference(taskDay).inDays;
            await addTaskNotification(
              title: 'Overdue Task',
              message:
                  '"$taskTitle" is $daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue!',
              taskId: taskData.join('|'),
              type: taskDeadline,
            );
          }
        }
      } catch (e) {
        // Skip malformed tasks
        continue;
      }
    }
  }

  // Get icon for notification type
  static String getNotificationIcon(String type) {
    switch (type) {
      case taskReminder:
        return '📋';
      case orderUpdate:
        return '📦';
      case taskDeadline:
        return '⏰';
      case systemNotification:
        return '🔔';
      case accountDeletion:
        return '🗑️';
      default:
        return '📢';
    }
  }
}
