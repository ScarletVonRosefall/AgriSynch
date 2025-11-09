import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'task_creation_dialog.dart';

class TaskEditDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final Function(Map<String, dynamic>) onSave;

  const TaskEditDialog({
    super.key,
    required this.task,
    required this.onSave,
  });

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController durationController;
  late DateTime selectedDueDate;
  late String selectedCategory;
  late String priority;
  late bool weatherDependent;
  late bool isRecurring;
  late String recurringType;
  bool isSaving = false;

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'No date';
    return DateFormat('MMM d, y').format(dateTime) + 
           ' at ' + 
           DateFormat('h:mm a').format(dateTime);
  }

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
      text: (widget.task['estimatedDuration'] ?? 30.0).toString(),
    );
    
    // Handle both Timestamp and DateTime types for dueDate
    final dueDateValue = widget.task['dueDate'];
    if (dueDateValue is Timestamp) {
      selectedDueDate = dueDateValue.toDate();
    } else if (dueDateValue is DateTime) {
      selectedDueDate = dueDateValue;
    } else {
      selectedDueDate = DateTime.now().add(const Duration(minutes: 5));
    }
    
    selectedCategory = widget.task['category'] ?? 'Other';
    
    // Initialize priority with exact match from the available priorities
    final storedPriority = widget.task['priority']?.toString().trim() ?? 'Medium';
    priority = TaskCreationDialog.priorities.firstWhere(
      (p) => p.toLowerCase() == storedPriority.toLowerCase(),
      orElse: () => TaskCreationDialog.priorities[1], // Default to 'Medium'
    );
    
    print('Initializing priority: stored=$storedPriority, selected=$priority');
    weatherDependent = widget.task['weatherDependent'] ?? false;
    isRecurring = widget.task['recurringTask'] ?? false;
    recurringType = widget.task['recurringFrequency'] ?? 'None';
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    durationController.dispose();
    super.dispose();
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
                    items: TaskCreationDialog.priorities.map((String p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          priority = value;
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
                    style: Theme.of(context).textTheme.bodyMedium,
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
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: TaskCreationDialog.categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Recurring Task"),
              value: isRecurring,
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
                value: recurringType,
                decoration: const InputDecoration(
                  labelText: "Repeat",
                  border: OutlineInputBorder(),
                ),
                items: TaskCreationDialog.recurringTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      recurringType = value;
                    });
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : () async {
            // Get the scaffold messenger before starting async work
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Validate input
            if (titleController.text.trim().isEmpty) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Title is required'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validate duration
            final duration = double.tryParse(durationController.text);
            if (duration == null || duration <= 0) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid duration'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            try {
              print('=== Edit Dialog Save Started ===');
              
              // Capture task updates synchronously
              final updatedTask = <String, dynamic>{
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'category': selectedCategory,
                'priority': priority,
                'weatherDependent': weatherDependent,
                'location': locationController.text.trim(),
                'dueDate': selectedDueDate,
                'estimatedDuration': duration,
                'recurringTask': isRecurring,
                'recurringFrequency': isRecurring ? recurringType : 'None',
              };

              print('Task updates prepared: $updatedTask');
              
              // Disable the save button while saving
              setState(() {
                isSaving = true;
              });

              // Call the save function with timeout
              await widget.onSave(updatedTask).timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException('Operation timed out'),
              );

              // Check if the widget is still mounted
              if (!mounted) return;

              // The parent will handle closing the dialog and showing success message
              
            } catch (e) {
              print('Error saving task: $e');
              
              if (!mounted) return;

              setState(() {
                isSaving = false;
              });

              // Show error message
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error saving task: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text("Save Changes"),
        ),
      ],
    );
  }
}