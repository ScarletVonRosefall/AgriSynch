import 'package:flutter/material.dart';
import 'dart:async';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgriSynchTasksPage extends StatefulWidget {
  const AgriSynchTasksPage({super.key});

  @override
  State<AgriSynchTasksPage> createState() => _AgriSynchTasksPageState();
}

class _AgriSynchTasksPageState extends State<AgriSynchTasksPage> {
  late final TaskService _taskService;
  List<Map<String, dynamic>> tasks = [];
  Timer? alarmTimer;
  Timer? alarmDismissTimer;
  bool isAlarmShowing = false;
  bool isDarkMode = false;
  int unreadNotifications = 0;
  BuildContext? alarmContext;

  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> taskCategories = [
    'All',
    'Feeding',
    'Cleaning',
    'Harvesting',
    'Maintenance',
    'Health Check',
    'Other',
  ];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Load critical data first
      await loadTasks();
      
      if (!mounted) return;
      
      // Load other data in parallel
      await Future.wait([
        _loadTheme(),
        _loadUnreadNotifications(),
      ]).timeout(const Duration(seconds: 5));
      
      if (!mounted) return;
      
      // Set up alarm timer and listen for task updates
      alarmTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => checkAlarms(),
      );
      
      // Listen for task updates
      _taskService.getTasks().listen((snapshot) {
        if (mounted) {
          setState(() {
            tasks = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
        }
      });
      
    } catch (e) {
      print('Error initializing data: $e');
      if (!mounted) return;
      setState(() {
        tasks = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    alarmTimer?.cancel();
    alarmDismissTimer?.cancel();
    cleanupAlarm();
    super.dispose();
  }

  void cleanupAlarm() {
    if (isAlarmShowing && alarmContext != null) {
      Navigator.of(alarmContext!).pop();
      alarmContext = null;
    }
    isAlarmShowing = false;
  }

  void dismissAlarm(Map<String, dynamic> task) async {
    alarmDismissTimer?.cancel();
    if (alarmContext != null) {
      Navigator.of(alarmContext!).pop();
      alarmContext = null;
    }
    
    final String taskId = task['id'];
    final int newAlarmCount = (task['alarmCount'] ?? 0) + 1;
    
    try {
      await _taskService.updateAlarmCount(taskId, newAlarmCount);
      
      if (mounted) {
        setState(() {
          task['alarmCount'] = newAlarmCount;
          isAlarmShowing = false;
        });
      }
    } catch (e) {
      print('Error updating alarm count: $e');
    }
  }

  // Load tasks from Firestore
  Future<void> loadTasks() async {
    if (!mounted) return;
    
    try {
      final snapshot = await _taskService.getTasks().first;
      
      if (!mounted) return;
      
      setState(() {
        tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Store the document ID
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error loading tasks: $e');
      if (!mounted) return;
      setState(() {
        tasks = [];
      });
    }
  }

  Future<void> _loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  // Load count of unread notifications
  Future<void> _loadUnreadNotifications() async {
    if (!mounted) return;
    
    try {
      final count = await NotificationHelper.getUnreadCount()
          .timeout(const Duration(seconds: 5));
          
      if (!mounted) return;
      
      setState(() {
        unreadNotifications = count;
      });
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          unreadNotifications = 0;
        });
      }
    }
  }

  // Show dialog to add a new task
  Future<void> addTask() async {
    if (!mounted) return;
    
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const TaskCreationDialog(),
      );

      if (!mounted) return;
      if (result == null) return;

      final DateTime dueDate = DateTime.now().add(const Duration(minutes: 5)); // Example due date

      await _taskService.createTask(
        title: result['title'] ?? 'New Task',
        description: result['description'] ?? '',
        dueDate: dueDate,
        priority: result['priority'] ?? 'Medium',
        category: result['category'],
        fieldLocation: result['location'],
        estimatedDuration: double.tryParse(result['duration'] ?? '30'),
        weatherDependent: result['weatherDependent'],
        recurringTask: result['isRecurring'],
        recurringFrequency: result['recurringType'] != 'None' ? result['recurringType'] : null,
        notes: '',
      );

      if (!mounted) return;

      // Create notification after successful save
      try {
        await NotificationHelper.addNotification(
          title: 'New Task Created',
          message: 'Task "${result['title']}" has been added to your schedule.',
          type: 'task_reminder',
        ).timeout(const Duration(seconds: 5));
        
        if (!mounted) return;
        _loadUnreadNotifications(); // Refresh notification count
      } catch (e) {
        // Handle notification error silently
      }
    } catch (e) {
      if (!mounted) return;
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> clearTasks() async {
    final List<String> taskIds = tasks.map((task) => task['id'] as String).toList();
    for (final taskId in taskIds) {
      await _taskService.deleteTask(taskId);
    }
  }

  void clearDoneTasks() async {
    final List<String> doneTaskIds = tasks
        .where((task) => task['completed'] == true)
        .map((task) => task['id'] as String)
        .toList();
        
    for (final taskId in doneTaskIds) {
      await _taskService.deleteTask(taskId);
    }
  }

  Future<void> toggleDone(int index, bool value) async {
    if (!mounted) return;
    final String taskId = tasks[index]['id'];
    final String taskTitle = tasks[index]['title'] ?? 'Untitled Task';

    try {
      if (value) {
        await _taskService.completeTask(taskId);
        
        // Create notification for task completion
        await NotificationHelper.addNotification(
          title: 'Task Completed',
          message: 'Task "$taskTitle" has been completed successfully!',
          type: 'task_reminder',
        );
      } else {
        await _taskService.updateTask(taskId, {'completed': false, 'completedAt': null});
      }
      
      await _loadUnreadNotifications(); // Refresh notification count
    } catch (e) {
      print('Error toggling task completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${value ? 'completing' : 'uncompleting'} task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> getFilteredTasks() {
    return tasks.where((task) {
      final titleMatch = task['title'].toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final categoryMatch =
          selectedCategory == 'All' || task['category'] == selectedCategory;
      return titleMatch && categoryMatch;
    }).toList();
  }

  // ... Rest of the UI code remains the same ...
  
  void editTask(int index) {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        task: tasks[index],
        onSave: (updatedTask) async {
          final String taskId = tasks[index]['id'];
          await _taskService.updateTask(taskId, {
            'title': updatedTask['title'],
            'description': updatedTask['description'],
            'category': updatedTask['category'],
            'priority': updatedTask['priority'],
            'weatherDependent': updatedTask['weatherDependent'],
            'location': updatedTask['location'],
            'duration': updatedTask['duration'],
            'dependencies': updatedTask['dependencies'],
          });
        },
      ),
    );
  }

  // Check if any tasks need alarm notifications
  void checkAlarms() {
    if (!mounted || isAlarmShowing) return;

    try {
      final now = TimeOfDay.now();
      final tasksToAlarm = <Map<String, dynamic>>[];

      // First collect all tasks that need alarms
      for (var task in tasks) {
        if (task['completed'] == true || (task['alarmCount'] ?? 0) >= 3) continue;

        final taskDate = (task['dueDate'] as Timestamp?)?.toDate();
        if (taskDate == null) continue;

        if (taskDate.hour == now.hour && taskDate.minute == now.minute) {
          tasksToAlarm.add(task);
        }
      }

      // If we found any tasks that need alarms, show the highest priority one
      if (tasksToAlarm.isNotEmpty) {
        // Sort by priority: Urgent > High > Medium > Low
        tasksToAlarm.sort((a, b) {
          final priorities = {'Urgent': 3, 'High': 2, 'Medium': 1, 'Low': 0};
          final priorityA = priorities[a['priority'] ?? 'Low'] ?? 0;
          final priorityB = priorities[b['priority'] ?? 'Low'] ?? 0;
          return priorityB.compareTo(priorityA);
        });

        showTaskAlarm(tasksToAlarm.first['title'], tasksToAlarm.first);
      }
    } catch (e) {
      print('Error checking alarms: $e');
      // If anything goes wrong, ensure we don't leave the alarm state stuck
      cleanupAlarm();
    }
  }

  void showTaskAlarm(String title, Map<String, dynamic> task) {
    if (isAlarmShowing || !mounted) return;
    
    // Clear any existing dismiss timer
    alarmDismissTimer?.cancel();
    
    // Set up auto-dismiss after 2 minutes to prevent stuck alarms
    alarmDismissTimer = Timer(const Duration(minutes: 2), () {
      dismissAlarm(task);
    });

    isAlarmShowing = true;
    showDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside to dismiss
      builder: (context) {
        alarmContext = context;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.alarm, color: Colors.red),
              const SizedBox(width: 8),
              const Text("Task Alarm"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Task \"$title\" Needs To Be Done!"),
              const SizedBox(height: 8),
              Text(
                "Category: ${task['category']}",
                style: const TextStyle(color: Colors.grey),
              ),
              if (task['location']?.isNotEmpty == true)
                Text(
                  "Location: ${task['location']}",
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => dismissAlarm(task),
              child: const Text("Snooze (10 min)"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Get task info before dismissing the dialog
                final String taskId = task['id'];
                final int index = tasks.indexOf(task);
                
                // Dismiss the alarm dialog first
                Navigator.of(context).pop();
                cleanupAlarm();
                
                // Then update the task state
                if (index != -1) {
                  try {
                    await _taskService.completeTask(taskId);
                    await NotificationHelper.addNotification(
                      title: 'Task Completed',
                      message: 'Task "${task['title']}" has been completed successfully!',
                      type: 'task_reminder',
                    );
                    await _loadUnreadNotifications();
                  } catch (e) {
                    print('Error completing task: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error marking task as complete'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Mark Complete"),
            ),
          ],
        );
      },
    ).then((_) {
      // Ensure alarm state is cleaned up if dialog is dismissed by tapping outside
      if (isAlarmShowing) {
        dismissAlarm(task);
      }
    });
  }

  // Rest of the code...
}