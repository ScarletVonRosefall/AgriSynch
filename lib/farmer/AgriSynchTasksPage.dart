import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_creation_dialog.dart';
import 'task_edit_dialog.dart';

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
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  BuildContext? alarmContext;

  // Date formatters for consistent display
  final DateFormat _dateFormat = DateFormat('MMM d, y');
  final DateFormat _timeFormat = DateFormat('h:mm a');
  
  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'No date';
    return '${_dateFormat.format(dateTime)} at ${_timeFormat.format(dateTime)}';
  }

  // Helper function to safely convert dueDate (which can be Timestamp or DateTime)
  DateTime? getTaskDueDate(dynamic dueDate) {
    if (dueDate == null) return null;
    if (dueDate is Timestamp) return dueDate.toDate();
    if (dueDate is DateTime) return dueDate;
    return null;
  }

  bool _areTaskListsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final task1 = list1[i];
      final task2 = list2[i];
      
      if (task1['id'] != task2['id']) return false;
      if (task1['title'] != task2['title']) return false;
      if (task1['completed'] != task2['completed']) return false;
      if (task1['updatedAt'] != task2['updatedAt']) return false;
    }
    
    return true;
  }

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
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    // Add a slight delay to ensure Firebase Auth is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _initializeData();
      }
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  StreamSubscription? _tasksSubscription;
  bool _isFirstLoad = true;
  Timer? _debounceTimer;
  Timer? _loadingTimeoutTimer;
  
  Future<void> _initializeData() async {
    if (!mounted) return;
    
    try {
      print('=== Initializing Tasks Page ===');
      setState(() {
        _isLoading = true;
      });

      // Set up a safety timeout to prevent stuck loading state
      _loadingTimeoutTimer?.cancel();
      _loadingTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isLoading) {
          print('WARNING: Loading timeout reached, forcing loading to stop');
          setState(() {
            _isLoading = false;
          });
        }
      });

      // Check authentication first
      final currentUser = _taskService.currentUserId;
      print('Current user ID: $currentUser');
      
      if (currentUser == null) {
        print('ERROR: No authenticated user found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to view tasks'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Cancel any existing subscriptions and timers
      await _tasksSubscription?.cancel();
      _debounceTimer?.cancel();
      
      print('Setting up tasks subscription...');
      // Set up subscription for updates with debouncing
      _tasksSubscription = _taskService.getTasks(limit: 50)
          .distinct() // Only emit if the data has changed
          .listen(
        (snapshot) {
          print('Tasks snapshot received: ${snapshot.docs.length} documents');
          if (!mounted) return;
          
          // Cancel any pending debounce
          _debounceTimer?.cancel();
          
          // Debounce setState calls
          _debounceTimer = Timer(
            Duration(milliseconds: _isFirstLoad ? 0 : 500), 
            () {
              if (!mounted) return;
              
              final newTasks = snapshot.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = doc.id;
                return data;
              }).toList();

              print('Processed ${newTasks.length} tasks');
              
              // Only update state if data has actually changed
              if (!_areTaskListsEqual(tasks, newTasks)) {
                setState(() {
                  tasks = newTasks;
                  _isFirstLoad = false;
                  if (_isLoading) _isLoading = false;
                });
                _loadingTimeoutTimer?.cancel(); // Cancel timeout since we loaded successfully
                print('Tasks state updated successfully');
              } else {
                print('Tasks data unchanged, skipping update');
                // Still need to turn off loading if this is first load
                if (_isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                  _loadingTimeoutTimer?.cancel();
                }
              }
            }
          );
        },
        onError: (error, stackTrace) {
          print('ERROR in tasks subscription: $error');
          print('Stack trace: $stackTrace');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _loadingTimeoutTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading tasks: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
      
      print('Loading notifications...');
      // Load notifications
      await _loadUnreadNotifications().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Warning: Notifications load timed out');
        },
      );
      
      if (!mounted) return;
      
      print('Setting up alarm timer...');
      // Set up alarm timer
      alarmTimer?.cancel(); // Cancel any existing timer
      alarmTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => checkAlarms(),
      );
      
      print('=== Tasks initialization completed ===');
      
    } catch (e, stackTrace) {
      print('ERROR initializing data: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        tasks = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _initializeData(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    alarmTimer?.cancel();
    alarmDismissTimer?.cancel();
    _tasksSubscription?.cancel();
    _debounceTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    cleanupAlarm();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void cleanupAlarm() {
    if (isAlarmShowing && alarmContext != null) {
      Navigator.of(alarmContext!).pop();
      alarmContext = null;
    }
    isAlarmShowing = false;
  }

  void dismissAlarm(Map<String, dynamic> task, {bool snooze = false}) async {
    alarmDismissTimer?.cancel();
    if (alarmContext != null) {
      Navigator.of(alarmContext!).pop();
      alarmContext = null;
    }
    
    final String taskId = task['id'];
    
    try {
      if (snooze) {
        // Get current due date and add 10 minutes
        final DateTime? currentDueDate = getTaskDueDate(task['dueDate']);
        if (currentDueDate == null) {
          throw Exception('Invalid due date');
        }
        final DateTime newDueDate = currentDueDate.add(const Duration(minutes: 10));
        
        // Update the task with new due date
        await _taskService.updateTask(taskId, {
          'dueDate': Timestamp.fromDate(newDueDate),
        });
      } else {
        // If not snoozing, increment alarm count
        final int newAlarmCount = (task['alarmCount'] ?? 0) + 1;
        await _taskService.updateAlarmCount(taskId, newAlarmCount);
        
        if (mounted) {
          setState(() {
            task['alarmCount'] = newAlarmCount;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          isAlarmShowing = false;
        });
      }
    } catch (e) {
      print('Error updating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${snooze ? 'snoozing' : 'dismissing'} task'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      await _taskService.createTask(
        title: result['title'] ?? 'New Task',
        description: result['description'] ?? '',
        dueDate: result['dueDate'],
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
        print('Notification error: $e');
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      // Log the actual error for debugging
      print('Error creating task: $e');
      print('Stack trace: $stackTrace');
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: ${e.toString()}'),
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
    if (!mounted || index < 0 || index >= tasks.length) return;

    final String taskId = tasks[index]['id'];
    final String taskTitle = tasks[index]['title'] ?? 'Untitled Task';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Optimistically update UI
    setState(() {
      tasks[index]['completed'] = value;
      tasks[index]['completedAt'] = value ? Timestamp.now() : null;
    });

    try {
      await Future.wait([
        // Update task completion status
        value 
          ? _taskService.completeTask(taskId)
              .timeout(const Duration(seconds: 5))
          : _taskService.updateTask(
              taskId, 
              {'completed': false, 'completedAt': null}
            ).timeout(const Duration(seconds: 5)),
            
        // Create notification if completing
        if (value) NotificationHelper.addNotification(
          title: 'Task Completed',
          message: 'Task "$taskTitle" has been completed successfully!',
          type: 'task_reminder',
        ).timeout(const Duration(seconds: 3)),
      ]);

      if (!mounted) return;
      
      // Refresh notification count
      _loadUnreadNotifications();

    } catch (e) {
      print('Error toggling task completion: $e');
      if (!mounted) return;

      // Revert optimistic update on error
      setState(() {
        tasks[index]['completed'] = !value;
        tasks[index]['completedAt'] = !value ? Timestamp.now() : null;
      });

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error ${value ? 'completing' : 'uncompleting'} task: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => toggleDone(index, value),
          ),
        ),
      );
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
  
    Future<void> editTask(int index) async {
    if (!mounted || index < 0 || index >= tasks.length) {
      print('Invalid task index: $index');
      return;
    }

    final task = Map<String, dynamic>.from(tasks[index]);
    print('Editing task: ${task['title']} (${task['id']})');

    // Store context reference for later use
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: TaskEditDialog(
            task: task,
            onSave: (Map<String, dynamic> updates) async {
              final String taskId = task['id'];
              print('Saving updates for task $taskId: $updates');

              try {
                // Convert DateTime to Timestamp for consistency before optimistic update
                final processedUpdates = Map<String, dynamic>.from(updates);
                if (processedUpdates['dueDate'] is DateTime) {
                  processedUpdates['dueDate'] = Timestamp.fromDate(processedUpdates['dueDate']);
                }
                
                // Update local state first (optimistic update)
                setState(() {
                  final taskIndex = tasks.indexWhere((t) => t['id'] == taskId);
                  if (taskIndex != -1) {
                    tasks[taskIndex] = {
                      ...tasks[taskIndex],
                      ...processedUpdates,
                      'id': taskId, // Preserve the ID
                    };
                  }
                });

                // Update the task using the service
                await _taskService.updateTask(taskId, updates)
                    .timeout(const Duration(seconds: 10));

                // Only proceed if still mounted
                if (!mounted) return;

                // Show success message
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Task updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Close the dialog
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // Refresh notifications
                _loadUnreadNotifications();
              } on TimeoutException {
                print('Task update timed out');
                if (!mounted) return;
                
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Update timed out. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                print('Error updating task: $e');
                if (!mounted) return;
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error updating task: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Error showing edit dialog: $e');
      if (!mounted) return;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error editing task: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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

        final taskDate = getTaskDueDate(task['dueDate']);
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
            ElevatedButton(
              onPressed: () async {
                // Get task info before dismissing the dialog
                final String taskId = task['id'];
                final String taskTitle = task['title'];
                
                // Dismiss the alarm dialog first
                Navigator.of(context).pop();
                alarmContext = null;
                isAlarmShowing = false;
                
                // Mark task as complete with proper error handling
                if (mounted) {
                  try {
                    await _taskService.completeTask(taskId);
                    
                    // Refresh the task list to show updated state
                    await loadTasks();
                    
                    if (mounted) {
                      await NotificationHelper.addNotification(
                        title: 'Task Completed',
                        message: 'Task "$taskTitle" has been completed successfully!',
                        type: 'task_reminder',
                      );
                      await _loadUnreadNotifications();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Task "$taskTitle" marked as complete'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error completing task: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error marking task as complete: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final backgroundColor = ThemeHelper.getBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        backgroundColor: const Color(0xFF1DBF73),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasks',
                              style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage and track your farm tasks',
                              style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AgriNotificationPage(),
                                  ),
                                );
                                _loadUnreadNotifications();
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          if (unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadNotifications > 9
                                      ? '9+'
                                      : unreadNotifications.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar inside header
                  Container(
                    height: 42,
                    decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: ThemeHelper.getIconColor(isDarkMode)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              border: InputBorder.none,
                              hintStyle: ThemeHelper.getHintTextStyle(isDark: isDarkMode),
                            ),
                            style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Debug section for loading issues
            if (_isLoading) 
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tasks are taking a while to load...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('=== MANUAL DEBUG REFRESH ===');
                        setState(() {
                          _isLoading = false;
                        });
                        _initializeData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Force Refresh'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Category filters with improved styling
            SizedBox(
              height: 50,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: taskCategories.length,
                  itemBuilder: (context, index) {
                    final category = taskCategories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? Colors.white : Colors.black87),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        selectedColor: const Color(0xFF1DBF73),
                        backgroundColor: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = selected ? category : 'All';
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tasks list with improved styling
            Expanded(
              child: getFilteredTasks().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: isDarkMode
                                ? Colors.white54
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a new task to get started',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: getFilteredTasks().length,
                      itemBuilder: (context, index) {
                        final task = getFilteredTasks()[index];
                        final originalIndex = tasks.indexOf(task);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.1 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Dismissible(
                            key: Key(task['id']),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: Text('Are you sure you want to delete "${task['title']}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await _taskService.deleteTask(task['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Task "${task['title']}" deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        // Re-create the task
                                        final dueDate = getTaskDueDate(task['dueDate']);
                                        if (dueDate == null) return;
                                        
                                        await _taskService.createTask(
                                          title: task['title'],
                                          description: task['description'] ?? '',
                                          dueDate: dueDate,
                                          priority: task['priority'] ?? 'Medium',
                                          category: task['category'],
                                          fieldLocation: task['location'],
                                          estimatedDuration: task['duration']?.toDouble(),
                                          weatherDependent: task['weatherDependent'] ?? false,
                                          recurringTask: false,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error deleting task'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                task['title'] ?? 'Untitled Task',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  decoration: task['completed'] == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task['description']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task['description'],
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${formatDateTime(getTaskDueDate(task['dueDate']))}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.white54
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => editTask(originalIndex),
                                  color: const Color(0xFF1DBF73),
                                  tooltip: 'Edit task',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    // Show confirmation dialog
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Task'),
                                        content: Text('Are you sure you want to delete "${task['title']}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      try {
                                        await _taskService.deleteTask(task['id']);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Task "${task['title']}" deleted'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error deleting task: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  color: Colors.red,
                                  tooltip: 'Delete task',
                                ),
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: task['completed'] == true,
                                    onChanged: (value) =>
                                        toggleDone(originalIndex, value ?? false),
                                    activeColor: const Color(0xFF1DBF73),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    ),
            ),
          ],
        ),
    );
  }
}