import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TestTaskCreation extends StatelessWidget {
  TestTaskCreation({super.key});

  final TaskService _taskService = TaskService();

  Future<void> _createTestTask(BuildContext context) async {
    try {
      await _taskService.createTask(
        title: 'Water corn field',
        description: 'Water the corn field in Section A',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        priority: 'high',
        category: 'Irrigation',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Task Creation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _createTestTask(context),
              child: const Text('Create Test Task'),
            ),
            const SizedBox(height: 20),
            StreamBuilder(
              stream: _taskService.getTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final tasks = snapshot.data?.docs ?? [];
                return Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index].data();
                      return ListTile(
                        title: Text(task['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['description'] ?? ''),
                            Text('Priority: ${task['priority']}'),
                            Text('Category: ${task['category'] ?? 'None'}'),
                            Text('Completed: ${task['completed'] ? 'Yes' : 'No'}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            try {
                              await _taskService.deleteTask(tasks[index].id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task deleted successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting task: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}