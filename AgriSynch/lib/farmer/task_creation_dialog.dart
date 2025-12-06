import 'package:flutter/material.dart';
import '../shared/theme_helper.dart';
import 'package:intl/intl.dart';

class TaskCreationDialog extends StatefulWidget {
  const TaskCreationDialog({super.key});

  static const List<String> priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const List<String> categories = [
    'Feeding',
    'Cleaning',
    'Harvesting',
    'Maintenance',
    'Health Check',
    'Other',
  ];
  static const List<String> recurringTypes = ['None', 'Daily', 'Weekly'];

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  DateTime selectedDueDate = DateTime.now().add(const Duration(minutes: 5));
  String selectedCategory = TaskCreationDialog.categories.last; // 'Other'
  bool isRecurring = false;
  String recurringType = TaskCreationDialog.recurringTypes.first; // 'None'
  String priority = TaskCreationDialog.priorities[1]; // 'Medium'
  bool weatherDependent = false;
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    durationController.dispose();
    super.dispose();
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'No date';
    return '${DateFormat('MMM d, y').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      title: Text(
        "Create New Task",
        style: TextStyle(
          fontFamily: 'Poppins',
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFFF8F8F8),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFFF8F8F8),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: "Field/Location",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "e.g., North Field, Greenhouse 2",
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFFF8F8F8),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Duration (minutes)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFF8F8F8),
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFF8F8F8),
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Poppins',
                    ),
                    items: [
                      for (final p in TaskCreationDialog.priorities)
                        DropdownMenuItem<String>(
                          value: p,
                          child: Text(p),
                        ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          priority = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Due: ${formatDateTime(selectedDueDate)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDueDate),
                      );
                      if (time != null && mounted) {
                        setState(() {
                          selectedDueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: const Text("Pick Date & Time"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                "Weather Dependent",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Text(
                "Task requires suitable weather conditions",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
              value: weatherDependent,
              activeThumbColor: const Color(0xFF1DBF73),
              onChanged: (bool value) {
                setState(() {
                  weatherDependent = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFFF8F8F8),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Poppins',
              ),
              items: [
                for (final category in TaskCreationDialog.categories)
                  DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                "Recurring Task",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              value: isRecurring,
              activeThumbColor: const Color(0xFF1DBF73),
              onChanged: (bool value) {
                setState(() {
                  isRecurring = value;
                  if (!value) {
                    recurringType = TaskCreationDialog.recurringTypes.first;
                  }
                });
              },
            ),
            if (isRecurring)
              DropdownButtonFormField<String>(
                initialValue: recurringType,
                decoration: InputDecoration(
                  labelText: "Repeat",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF3C3C3C)
                      : const Color(0xFFF8F8F8),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'Poppins',
                ),
                items: [
                  for (final type in TaskCreationDialog.recurringTypes)
                    DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      recurringType = newValue;
                    });
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text,
                'description': descriptionController.text,
                'dueDate': selectedDueDate,
                'category': selectedCategory,
                'isRecurring': isRecurring,
                'recurringType': recurringType,
                'priority': priority,
                'weatherDependent': weatherDependent,
                'location': locationController.text,
                'duration': durationController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DBF73),
            foregroundColor: Colors.white,
          ),
          child: const Text("Create Task"),
        ),
      ],
    );
  }
}
