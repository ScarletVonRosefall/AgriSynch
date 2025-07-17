import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    loadTasks();
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

  void addTask() async {
  final newTask = {
    'title': 'New Task',
    'time': '00:00 AM',
    'done': false,
    'alarmCount': 0, 
  };
  setState(() {
    tasks.add(newTask);
  });
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
    setState(
      () {
        tasks[index]['done'] = value;
      },
    );
    await saveTasks();
  }

void editTask(int index) {
  final titleController = TextEditingController(
    text: tasks[index]['title'],
  );
  String selectedTime = tasks[index]['time'];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Time: $selectedTime",
                    style: const TextStyle(fontSize: 16),
                  ),
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
            const SizedBox(height: 8),
            const Text(
              "Tasks are only for today.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() {
                tasks[index]['title'] = titleController.text;
                tasks[index]['time'] = selectedTime;
              });
              await saveTasks();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
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
            Flexible(
  child: ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, i) {
      final task = tasks[i];
      return GestureDetector(
        onTap: () => editTask(i),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEDC8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task: ${task['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Time: ${task['time']}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status: ${task['done'] ? 'Done' : 'Not Done'}'),
                  Switch(
                    activeColor: const Color(0xFFFFD54F),
                    value: task['done'],
                    onChanged: (val) => toggleDone(i, val),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ),
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
                    onPressed: clearDoneTasks,
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
                      "Clear Done Tasks",
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
