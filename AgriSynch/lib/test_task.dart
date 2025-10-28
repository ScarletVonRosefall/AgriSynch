import 'package:flutter/material.dart';
import 'services/task_service.dart';

class TestTaskPage extends StatelessWidget {
  TestTaskPage({Key? key}) : super(key: key);

  final TaskService _taskService = TaskService();

  Future<void> _createTestTask(BuildContext context) async {
    try {
      await _taskService.createTask(
        title: 'Water the Crops',
        description: 'Water the corn field in Section A',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        priority: 'high',
        category: 'Irrigation',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test task created successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Task Creation'),
      ),
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
                return Column(
                  children: [
                    Text('Total Tasks: ${tasks.length}'),
                    const SizedBox(height: 10),
                    ...tasks.map((doc) {
                      final data = doc.data();
                      return ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Text(data['priority'] ?? ''),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}