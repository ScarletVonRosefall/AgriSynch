import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    loadTasks();
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

  void addTask() async {
    final newTask = {
      'title': 'New Task',
      'time': '00:00 AM',
      'done': false,
    };
    setState(
      () {
        tasks.add(
          newTask,
        );
      },
    );
    await saveTasks();
  }

  void clearTasks() async {
    setState(
      () {
        tasks.clear();
      },
    );
    await saveTasks();
  }

  void toggleDone(
    int index,
    bool value,
  ) async {
    setState(
      () {
        tasks[index]['done'] = value;
      },
    );
    await saveTasks();
  }

  void editTask(
    int index,
  ) {
    final titleController = TextEditingController(
      text: tasks[index]['title'],
    );
    final timeController = TextEditingController(
      text: tasks[index]['time'],
    );

    showDialog(
      context: context,
      builder:
          (
            context,
          ) {
            return AlertDialog(
              title: const Text(
                "Edit Task",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                    ),
                  ),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: "Time",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    setState(
                      () {
                        tasks[index]['title'] = titleController.text;
                        tasks[index]['time'] = timeController.text;
                      },
                    );
                    await saveTasks();
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    "Save",
                  ),
                ),
              ],
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF2FBE0,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF00C853,
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Good Morning!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'Agrisynch User!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(
              right: 16.0,
            ),
            child: Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Container(
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFB9F6CA,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '• ${tasks.length} Tasks Today',
                        ),
                        const Text(
                          '• Eggs Collected: 950',
                        ),
                        const Text(
                          '• 1 Pending Order',
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(
                      0xFFFFF59D,
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),

            const Text(
              "Today's Reminders",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            ...tasks.asMap().entries.map(
              (
                entry,
              ) {
                final i = entry.key;
                final task = entry.value;
                return GestureDetector(
                  onTap: () => editTask(
                    i,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFDCEDC8,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task: ${task['title']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Time: ${task['time']}',
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${task['done'] ? 'Done' : 'Not Done'}',
                            ),
                            Switch(
                              activeColor: const Color(
                                0xFFFFD54F,
                              ),
                              value: task['done'],
                              onChanged:
                                  (
                                    val,
                                  ) => toggleDone(
                                    i,
                                    val,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: addTask,
              child: Container(
                width: double.infinity,
                height: 80,
                margin: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: Colors.green.shade300,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF00C853,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      "Add New Task",
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: clearTasks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFF5252,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      "Clear All Task",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
