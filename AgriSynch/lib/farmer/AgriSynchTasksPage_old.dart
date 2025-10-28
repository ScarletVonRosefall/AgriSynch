import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/task_service.dart';

class AgriSynchTasksPage extends StatefulWidget {
  const AgriSynchTasksPage({super.key});

  @override
  State<AgriSynchTasksPage> createState() => _AgriSynchTasksPageState();
}

class _AgriSynchTasksPageState extends State<AgriSynchTasksPage> {
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

  // Initialize the tasks page when widget is first created
  bool _isInitialized = false;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      
      // Set up alarm timer
      alarmTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => checkAlarms(),
      );
    } catch (e) {
      // Handle initialization error
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

  // Clean up all resources when page is closed
  @override
  void dispose() {
    // Cancel all timers
    alarmTimer?.cancel();
    alarmDismissTimer?.cancel();
    _saveDebouncer?.cancel();
    
    // Close any open dialogs
    cleanupAlarm();
    
    // If there's a pending save, try to complete it
    if (_isSaving) {
      saveTasks().then((_) {
        super.dispose();
      }).catchError((_) {
        super.dispose();
      });
    } else {
      super.dispose();
    }
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
    
    final TaskService taskService = TaskService();
    final String taskId = task['id'];
    final int newAlarmCount = (task['alarmCount'] ?? 0) + 1;
    
    setState(() {
      task['alarmCount'] = newAlarmCount;
      isAlarmShowing = false;
    });
    
    await taskService.updateAlarmCount(taskId, newAlarmCount);
  }

  bool _isSaving = false;
  Timer? _saveDebouncer;

  // Load tasks from Firestore
  Future<void> loadTasks() async {
    if (!mounted) return;
    
    try {
      final TaskService taskService = TaskService();
      final snapshot = await taskService.getTasks().first;
      
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

  // Save tasks to device storage with debouncing
  Future<void> saveTasks() async {
    if (!mounted || _isSaving) return;
    
    // Cancel any pending save
    _saveDebouncer?.cancel();
    
    // Debounce multiple saves
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      _isSaving = true;
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 5));
            
        if (!mounted) return;
        
        await prefs.setString('tasks', json.encode(tasks))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // Handle save error silently
      } finally {
        if (mounted) {
          _isSaving = false;
        }
      }
    });
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

      final newTask = {
        'title': result['title'] ?? 'New Task',
        'description': result['description'] ?? '',
        'time': result['time'] ?? '00:00 AM',
        'category': result['category'] ?? 'Other',
        'done': false,
        'alarmCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'completedAt': null,
        'isRecurring': result['isRecurring'] ?? false,
        'recurringType': result['recurringType'] ?? 'None',
        'priority': result['priority'] ?? 'Medium',
        'weatherDependent': result['weatherDependent'] ?? false,
        'location': result['location'] ?? '',
        'duration': result['duration'] ?? '30',
        'dependencies': result['dependencies'] ?? [],
      };

      // Save task first
      setState(() {
        tasks.add(newTask);
      });
      
      // Start save operation
      await saveTasks();
      
      if (!mounted) return;

      // Create notification after successful save
      try {
        await NotificationHelper.addNotification(
          title: 'New Task Created',
          message: 'Task "${newTask['title']}" has been added to your schedule.',
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
    setState(() {
      tasks.clear();
    });
    await saveTasks();
  }

  void clearDoneTasks() async {
    setState(() {
      tasks.removeWhere((task) => task['done'] == true);
    });
    await saveTasks();
  }

  void toggleDone(int index, bool value) async {
    setState(() {
      tasks[index]['done'] = value;
      if (value) {
        tasks[index]['completedAt'] = DateTime.now().toIso8601String();
        // Create notification for task completion
        NotificationHelper.addNotification(
          title: 'Task Completed',
          message:
              'Task "${tasks[index]['title']}" has been completed successfully!',
          type: 'task_reminder',
        );
      } else {
        tasks[index]['completedAt'] = null;
      }
    });
    await saveTasks();
    _loadUnreadNotifications(); // Refresh notification count
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00E676),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Summary",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• ${tasks.length} Total Tasks',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '• ${tasks.where((t) => t['done'] == true).length} Completed',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '• ${tasks.where((t) => t['done'] != true).length} Pending',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Filter by Category: ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF00C853),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FBE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                items: taskCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTasksList() {
    final filteredTasks = getFilteredTasks();
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.task_alt, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks found',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or add a new task',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, i) {
        final task = filteredTasks[i];
        final originalIndex = tasks.indexOf(task);

        return GestureDetector(
          onTap: () => editTask(originalIndex),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: task['priority'] != null
                  ? Border.all(
                      color: _getPriorityColor(task['priority']),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2FBE0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getCategoryIcon(task['category'] ?? 'Other'),
                        color: const Color(0xFF00C853),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] ?? 'Untitled Task',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: task['done']
                                  ? Colors.grey
                                  : const Color(0xFF2E7D32),
                              decoration: task['done']
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (task['description'] != null &&
                              task['description'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task['description'],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch(
                      value: task['done'] ?? false,
                      onChanged: (val) => toggleDone(originalIndex, val),
                      activeThumbColor: const Color(0xFF00C853),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task['time'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2FBE0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task['category'] ?? 'Other',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF00C853),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: task['done'] ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${task['done'] ? 'Completed' : 'Pending'}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: task['done'] ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: clearDoneTasks,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              "Clear Done",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: clearTasks,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text(
              "Clear All",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => showTaskStatistics(context),
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text(
              "Stats",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Feeding':
        return Icons.restaurant;
      case 'Cleaning':
        return Icons.cleaning_services;
      case 'Harvesting':
        return Icons.agriculture;
      case 'Maintenance':
        return Icons.build;
      case 'Health Check':
        return Icons.health_and_safety;
      default:
        return Icons.task;
    }
  }

  void showTaskStatistics(BuildContext context) {
    final completedTasks = tasks.where((t) => t['done'] == true).length;
    final pendingTasks = tasks.length - completedTasks;

    final categoryStats = <String, int>{};
    for (final task in tasks) {
      final category = task['category'] ?? 'Other';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text("Task Statistics"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                "Total Tasks",
                tasks.length.toString(),
                Icons.task_alt,
              ),
              _buildStatRow(
                "Completed",
                completedTasks.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatRow(
                "Pending",
                pendingTasks.toString(),
                Icons.pending,
                Colors.orange,
              ),

              const SizedBox(height: 16),
              const Text(
                "By Category:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...categoryStats.entries.map(
                (entry) => _buildStatRow(
                  entry.key,
                  entry.value.toString(),
                  getCategoryIcon(entry.key),
                ),
              ),

              if (completedTasks > 0) ...[
                const SizedBox(height: 16),
                _buildStatRow(
                  "Completion Rate",
                  "${((completedTasks / tasks.length) * 100).toStringAsFixed(1)}%",
                  Icons.trending_up,
                  Colors.blue,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void editTask(int index) {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        task: tasks[index],
        onSave: (updatedTask) async {
          setState(() {
            tasks[index] = updatedTask;
          });
          await saveTasks();
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
        if (task['done'] == true || (task['alarmCount'] ?? 0) >= 3) continue;

        final taskTimeStr = task['time'];
        if (taskTimeStr == null) continue;

        final timeParts = taskTimeStr.split(' ');
        if (timeParts.length != 2) continue;

        try {
          final hm = timeParts[0].split(':');
          if (hm.length != 2) continue;

          final ampm = timeParts[1].toUpperCase();
          if (ampm != 'AM' && ampm != 'PM') continue;

          int hour = int.tryParse(hm[0]) ?? -1;
          int minute = int.tryParse(hm[1]) ?? -1;
          if (hour < 0 || minute < 0) continue;

          if (ampm == 'PM' && hour != 12) hour += 12;
          if (ampm == 'AM' && hour == 12) hour = 0;

          // Check if task time matches current time
          if (hour == now.hour && minute == now.minute) {
            tasksToAlarm.add(task);
          }
        } catch (e) {
          // Skip malformed time strings
          continue;
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
              onPressed: () {
                dismissAlarm(task);
                // Mark task as done
                final index = tasks.indexOf(task);
                if (index != -1) {
                  toggleDone(index, true);
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

  // Build the tasks page UI with fixed header and scrollable content
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Fixed Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Management',
                            style: ThemeHelper.getHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Let's Get Tasks Done!",
                            style: ThemeHelper.getSubHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
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
                              // Reload notification count when returning
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
                // Search Section
                Container(
                  height: 42,
                  decoration: ThemeHelper.getContainerDecoration(
                    isDark: isDarkMode,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: ThemeHelper.getIconColor(isDarkMode),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            border: InputBorder.none,
                            hintStyle: ThemeHelper.getHintTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                          style: ThemeHelper.getBodyTextStyle(
                            isDark: isDarkMode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    // Filter Section
                    _buildFilterSection(),
                    const SizedBox(height: 16),
                    // Tasks Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Tasks",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        GestureDetector(
                          onTap: addTask,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Add Task',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tasks List - Using a constrained height container instead of Expanded
                    SizedBox(
                      height: 400, // Fixed height for tasks list
                      child: _buildTasksList(),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Task Creation Dialog
class TaskCreationDialog extends StatefulWidget {
  const TaskCreationDialog({super.key});

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  String selectedTime = '12:00 PM';
  String selectedCategory = 'Other';
  bool isRecurring = false;
  String recurringType = 'None';
  String priority = 'Medium';
  bool weatherDependent = false;
  List<String> selectedDependencies = [];

  final List<String> categories = [
    'Feeding',
    'Cleaning',
    'Harvesting',
    'Maintenance',
    'Health Check',
    'Other',
  ];

  final List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  final List<String> recurringTypes = ['None', 'Daily', 'Weekly'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Task"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Field/Location",
                border: OutlineInputBorder(),
                hintText: "e.g., North Field, Greenhouse 2",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Duration (minutes)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(),
                    ),
                    items: priorities.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        priority = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text("Time: $selectedTime")),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked.format(context);
                      });
                    }
                  },
                  child: const Text("Pick Time"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Weather Dependent"),
              subtitle: const Text("Task requires suitable weather conditions"),
              value: weatherDependent,
              onChanged: (bool value) {
                setState(() {
                  weatherDependent = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text,
                'description': descriptionController.text,
                'time': selectedTime,
                'category': selectedCategory,
                'isRecurring': isRecurring,
                'recurringType': recurringType,
                'priority': priority,
                'weatherDependent': weatherDependent,
                'location': locationController.text,
                'duration': durationController.text,
                'dependencies': selectedDependencies,
              });
            }
          },
          child: const Text("Create Task"),
        ),
      ],
    );
  }
}

// Task Edit Dialog
class TaskEditDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final Function(Map<String, dynamic>) onSave;

  const TaskEditDialog({super.key, required this.task, required this.onSave});

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController durationController;
  late String selectedTime;
  late String selectedCategory;
  late String priority;
  late bool weatherDependent;
  late List<String> selectedDependencies;

  final List<String> categories = [
    'Feeding',
    'Cleaning',
    'Harvesting',
    'Maintenance',
    'Health Check',
    'Other',
  ];

  final List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task['title'] ?? '');
    descriptionController = TextEditingController(
      text: widget.task['description'] ?? '',
    );
    locationController = TextEditingController(
      text: widget.task['location'] ?? '',
    );
    durationController = TextEditingController(
      text: widget.task['duration']?.toString() ?? '30',
    );
    selectedTime = widget.task['time'] ?? '00:00 AM';
    selectedCategory = widget.task['category'] ?? 'Other';
    priority = widget.task['priority'] ?? 'Medium';
    weatherDependent = widget.task['weatherDependent'] ?? false;
    selectedDependencies = List<String>.from(widget.task['dependencies'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Task"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Field/Location",
                border: OutlineInputBorder(),
                hintText: "e.g., North Field, Greenhouse 2",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Duration (minutes)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(),
                    ),
                    items: priorities.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        priority = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text("Time: $selectedTime")),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked.format(context);
                      });
                    }
                  },
                  child: const Text("Pick Time"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Weather Dependent"),
              subtitle: const Text("Task requires suitable weather conditions"),
              value: weatherDependent,
              onChanged: (bool value) {
                setState(() {
                  weatherDependent = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              final updatedTask = Map<String, dynamic>.from(widget.task);
              updatedTask['title'] = titleController.text;
              updatedTask['description'] = descriptionController.text;
              updatedTask['time'] = selectedTime;
              updatedTask['category'] = selectedCategory;
              updatedTask['priority'] = priority;
              updatedTask['weatherDependent'] = weatherDependent;
              updatedTask['location'] = locationController.text;
              updatedTask['duration'] = durationController.text;
              updatedTask['dependencies'] = selectedDependencies;

              widget.onSave(updatedTask);
              Navigator.pop(context);
            }
          },
          child: const Text("Save Changes"),
        ),
      ],
    );
  }
}
