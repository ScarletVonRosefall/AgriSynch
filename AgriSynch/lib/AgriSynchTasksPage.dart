import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'theme_helper.dart';

class AgriSynchTasksPage
    extends
        StatefulWidget {
  const AgriSynchTasksPage({
    Key? key,
  }) : super(
         key: key,
       );
       

  @override
  State<
    AgriSynchTasksPage
  >
  createState() => _AgriSynchTasksPageState();
}

class _AgriSynchTasksPageState
    extends
        State<
          AgriSynchTasksPage
        > {
  List<
    Map<
      String,
      dynamic
    >
  >
  tasks = [];

  Timer? alarmTimer;

  bool isAlarmShowing = false;
  bool isDarkMode = false;
  
  String searchQuery = '';
  String selectedCategory = 'All';
  
  final List<String> taskCategories = [
    'All', 'Feeding', 'Cleaning', 'Harvesting', 'Maintenance', 'Health Check', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    loadTasks();
    _loadTheme();
    alarmTimer = Timer.periodic(const Duration(seconds: 10), (_) => checkAlarms());
  }

  @override
  void dispose() {
    alarmTimer?.cancel();
    super.dispose();
  }

  Future<
    void
  >
  loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getString(
      'tasks',
    );
    if (savedTasks !=
        null) {
      setState(
        () {
          tasks =
              List<
                Map<
                  String,
                  dynamic
                >
              >.from(
                json.decode(
                  savedTasks,
                ),
              );
        },
      );
    }
  }

  Future<
    void
  >
  saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      json.encode(
        tasks,
      ),
    );
  }

  _loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  void addTask() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const TaskCreationDialog(),
    );
    
    if (result != null) {
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
      };
      setState(() {
        tasks.add(newTask);
      });
      await saveTasks();
    }
  }

  void clearTasks() async {
    setState(
      () {
        tasks.clear();
      },
    );
    await saveTasks();
  }
  
  void clearDoneTasks() async {
    setState(
      () {
        tasks.removeWhere(
          (task) => task['done'] == true,
        );
      },
    );
    await saveTasks();
  }

  void toggleDone(
    int index,
    bool value,
  ) async {
    setState(() {
      tasks[index]['done'] = value;
      if (value) {
        tasks[index]['completedAt'] = DateTime.now().toIso8601String();
      } else {
        tasks[index]['completedAt'] = null;
      }
    });
    await saveTasks();
  }

  List<Map<String, dynamic>> getFilteredTasks() {
    return tasks.where((task) {
      final titleMatch = task['title'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final categoryMatch = selectedCategory == 'All' || task['category'] == selectedCategory;
      return titleMatch && categoryMatch;
    }).toList();
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676),
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
            child: const Icon(
              Icons.task_alt,
              color: Colors.white,
              size: 30,
            ),
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
              child: const Icon(
                Icons.task_alt,
                size: 64,
                color: Colors.grey,
              ),
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
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
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
                              color: task['done'] ? Colors.grey : const Color(0xFF2E7D32),
                              decoration: task['done'] ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (task['description'] != null && task['description'].isNotEmpty) ...[
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
                      activeColor: const Color(0xFF00C853),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _buildStatRow("Total Tasks", tasks.length.toString(), Icons.task_alt),
              _buildStatRow("Completed", completedTasks.toString(), Icons.check_circle, Colors.green),
              _buildStatRow("Pending", pendingTasks.toString(), Icons.pending, Colors.orange),
              
              const SizedBox(height: 16),
              const Text("By Category:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              ...categoryStats.entries.map((entry) => 
                _buildStatRow(entry.key, entry.value.toString(), getCategoryIcon(entry.key))
              ).toList(),
              
              if (completedTasks > 0) ...[
                const SizedBox(height: 16),
                _buildStatRow(
                  "Completion Rate", 
                  "${((completedTasks / tasks.length) * 100).toStringAsFixed(1)}%", 
                  Icons.trending_up,
                  Colors.blue
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

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
void checkAlarms() {
  final now = TimeOfDay.now();
  for (var task in tasks) {
    if (!task['done'] && (task['alarmCount'] ?? 0) < 3) {
      final taskTimeStr = task['time'];
      final timeParts = taskTimeStr.split(' ');
      if (timeParts.length == 2) {
        final hm = timeParts[0].split(':');
        final ampm = timeParts[1];
        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        if (hour == now.hour && minute == now.minute) {
          showTaskAlarm(task['title'], task);
          break;
        }
      }
    }
  }
}

void showTaskAlarm(String title, Map<String, dynamic> task) {
  if (isAlarmShowing) return;
  isAlarmShowing = true;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Task Alarm"),
      content: Text("Task \"$title\" Needs To Be Done!"),
      actions: [
        TextButton(
          onPressed: () async {
            setState(() {
              task['alarmCount'] = (task['alarmCount'] ?? 0) + 1;
            });
            isAlarmShowing = false;
            await saveTasks();
            Navigator.pop(context);
          },
          child: const Text("Okay"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Top Green Header ---
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
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Let's Get Tasks Done!",
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Section
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
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
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
          
          const SizedBox(height: 16),
          
          // --- Content Area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  // Tasks List
                  Expanded(child: _buildTasksList()),
                  const SizedBox(height: 16),
                  // Action Buttons
                  _buildActionButtons(),
                ],
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
  const TaskCreationDialog({Key? key}) : super(key: key);

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedTime = '12:00 PM';
  String selectedCategory = 'Other';
  bool isRecurring = false;
  String recurringType = 'None';

  final List<String> categories = [
    'Feeding', 'Cleaning', 'Harvesting', 'Maintenance', 'Health Check', 'Other'
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
            Row(
              children: [
                Expanded(
                  child: Text("Time: $selectedTime"),
                ),
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
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
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

  const TaskEditDialog({
    Key? key,
    required this.task,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late String selectedTime;
  late String selectedCategory;

  final List<String> categories = [
    'Feeding', 'Cleaning', 'Harvesting', 'Maintenance', 'Health Check', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task['title'] ?? '');
    descriptionController = TextEditingController(text: widget.task['description'] ?? '');
    selectedTime = widget.task['time'] ?? '00:00 AM';
    selectedCategory = widget.task['category'] ?? 'Other';
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
            Row(
              children: [
                Expanded(
                  child: Text("Time: $selectedTime"),
                ),
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
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
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
