import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'theme_helper.dart';
import 'notification_helper.dart';
import 'AgriNotificationPage.dart';

class AgriSynchCalendarPage
    extends
        StatefulWidget {
  const AgriSynchCalendarPage({
    super.key,
  });

  @override
  State<
    AgriSynchCalendarPage
  >
  createState() => _CalendarPageState();
}

class _CalendarPageState
    extends
        State<
          AgriSynchCalendarPage
        > {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<
    String,
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  _events = {};
  List<
    Map<
      String,
      dynamic
    >
  >
  _tasks = [];
  bool isDarkMode = false;
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadTasks();
    _loadTheme();
    _loadUnreadNotifications();
  }

  Future<
    void
  >
  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString(
      'calendar_events',
    );
    if (storedData !=
        null) {
      setState(
        () {
          final decoded = json.decode(
            storedData,
          );
          _events = {};
          decoded.forEach(
            (
              key,
              value,
            ) {
              _events[key] =
                  List<
                    Map<
                      String,
                      dynamic
                    >
                  >.from(
                    value.map(
                      (
                        item,
                      ) =>
                          item
                              is String
                          ? {
                              'title': item,
                              'type': 'event',
                              'category': 'Other',
                            }
                          : Map<
                              String,
                              dynamic
                            >.from(
                              item,
                            ),
                    ),
                  );
            },
          );
        },
      );
    }
  }

  Future<
    void
  >
  _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString(
      'tasks',
    );
    if (storedTasks !=
        null) {
      setState(
        () {
          _tasks =
              List<
                Map<
                  String,
                  dynamic
                >
              >.from(
                json.decode(
                  storedTasks,
                ),
              );
          _syncTasksToCalendar();
        },
      );
    }
  }

  void _syncTasksToCalendar() {
    // Clear existing task entries from calendar
    _events.forEach(
      (
        key,
        events,
      ) {
        events.removeWhere(
          (
            event,
          ) =>
              event['type'] ==
              'task',
        );
      },
    );

    // Add tasks to calendar based on their scheduled time
    for (var task in _tasks) {
      final today = DateTime.now();
      final dateKey = today.toIso8601String().split(
        'T',
      )[0];

      if (_events[dateKey] ==
          null) {
        _events[dateKey] = [];
      }

      _events[dateKey]!.add(
        {
          'title':
              task['title'] ??
              'Untitled Task',
          'type': 'task',
          'category':
              task['category'] ??
              'Other',
          'time':
              task['time'] ??
              '',
          'done':
              task['done'] ??
              false,
          'description':
              task['description'] ??
              '',
        },
      );
    }

    _saveEvents();
  }

  Future<
    void
  >
  _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'calendar_events',
      json.encode(
        _events,
      ),
    );
  }

  _loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(
      () {},
    );
  }

  void _loadUnreadNotifications() async {
    final count = await NotificationHelper.getUnreadCount();
    setState(
      () {
        unreadNotifications = count;
      },
    );
  }

  void _addEvent(
    String title,
    String category,
    String description,
  ) {
    final key = _selectedDay!.toIso8601String().split(
      'T',
    )[0];
    if (_events[key] ==
        null) {
      _events[key] = [];
    }
    _events[key]!.add(
      {
        'title': title,
        'type': 'event',
        'category': category,
        'description': description,
      },
    );
    _saveEvents();
    setState(
      () {},
    );

    // Create notification for new event
    NotificationHelper.addNotification(
      title: 'Calendar Event Added',
      message: 'Event "$title" has been scheduled successfully!',
      type: 'system',
    );
    _loadUnreadNotifications();
  }

  List<
    Map<
      String,
      dynamic
    >
  >
  _getEventsForDay(
    DateTime day,
  ) {
    final key = day.toIso8601String().split(
      'T',
    )[0];
    return _events[key] ??
        [];
  }

  Color _getCategoryColor(
    String category,
  ) {
    switch (category) {
      case 'Feeding':
        return Colors.orange;
      case 'Cleaning':
        return Colors.blue;
      case 'Harvesting':
        return Colors.green;
      case 'Maintenance':
        return Colors.purple;
      case 'Health Check':
        return Colors.red;
      case 'Other':
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(
    String category,
  ) {
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
        return Icons.event;
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Other';

    final categories = [
      'Feeding',
      'Cleaning',
      'Harvesting',
      'Maintenance',
      'Health Check',
      'Other',
    ];

    showDialog(
      context: context,
      builder:
          (
            context,
          ) => StatefulBuilder(
            builder:
                (
                  context,
                  setDialogState,
                ) => AlertDialog(
                  title: const Text(
                    'Add Calendar Event',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Event Title',
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        DropdownButtonFormField<
                          String
                        >(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                          items: categories.map(
                            (
                              category,
                            ) {
                              return DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(
                                        category,
                                      ),
                                      color: _getCategoryColor(
                                        category,
                                      ),
                                      size: 20,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      category,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              (
                                value,
                              ) {
                                setDialogState(
                                  () {
                                    selectedCategory = value!;
                                  },
                                );
                              },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          _addEvent(
                            titleController.text.trim(),
                            selectedCategory,
                            descriptionController.text.trim(),
                          );
                        }
                        Navigator.pop(
                          context,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00C853,
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final selectedDateKey = _selectedDay?.toIso8601String().split(
      'T',
    )[0];
    final selectedEvents =
        _events[selectedDateKey] ??
        [];

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(
        isDarkMode,
      ),
      body: Column(
        children: [
          // --- Fixed Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              40,
              20,
              20,
            ),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(
              isDark: isDarkMode,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.2,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(
                          context,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agricultural Calendar',
                            style: ThemeHelper.getHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Plan your farm activities',
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
                            color: Colors.white.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (
                                        _,
                                      ) => const AgriNotificationPage(),
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
                        if (unreadNotifications >
                            0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(
                                2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadNotifications >
                                        9
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
              ],
            ),
          ),

          // --- Scrollable Calendar Section ---
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Calendar Widget
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            0.05,
                          ),
                          blurRadius: 8,
                          offset: const Offset(
                            0,
                            2,
                          ),
                        ),
                      ],
                    ),
                    child:
                        TableCalendar<
                          Map<
                            String,
                            dynamic
                          >
                        >(
                          firstDay: DateTime.utc(
                            2020,
                          ),
                          lastDay: DateTime.utc(
                            2030,
                          ),
                          focusedDay: _focusedDay,
                          selectedDayPredicate:
                              (
                                day,
                              ) => isSameDay(
                                _selectedDay,
                                day,
                              ),
                          eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            selectedDecoration: const BoxDecoration(
                              color: Color(
                                0xFF00C853,
                              ),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(
                                0xFF00E676,
                              ),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                            canMarkersOverflow: true,
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onDaySelected:
                              (
                                selectedDay,
                                focusedDay,
                              ) {
                                setState(
                                  () {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  },
                                );
                              },
                        ),
                    ), // Close Container

                    const SizedBox(
                      height: 16,
                    ),

                    // Selected Date Info and Add Button
                    if (_selectedDay !=
                        null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF00E676,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Date',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '${selectedEvents.length} events scheduled',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                            ),
                            label: const Text(
                              'Add Event',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(
                                0xFF00C853,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ], // Close the conditional array for if (_selectedDay != null)
                    
                    // Events List - Using a constrained height container instead of Expanded
                    SizedBox(
                      height: 300, // Fixed height for events list
                      child: selectedEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.event_note,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                const Text(
                                  'No events scheduled',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                const Text(
                                  'Select a date and add your farm activities',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedEvents.length,
                            itemBuilder:
                                (
                                  context,
                                  index,
                                ) {
                                  final event = selectedEvents[index];
                                  final isTask =
                                      event['type'] ==
                                      'task';

                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            0.05,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(
                                            0,
                                            2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(
                                        16,
                                      ),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                              _getCategoryColor(
                                                event['category'] ??
                                                    'Other',
                                              ).withOpacity(
                                                0.1,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(
                                            event['category'] ??
                                                'Other',
                                          ),
                                          color: _getCategoryColor(
                                            event['category'] ??
                                                'Other',
                                          ),
                                          size: 24,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event['title'] ??
                                                  'Untitled',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color:
                                                    isTask &&
                                                        event['done']
                                                    ? Colors.grey
                                                    : Colors.black87,
                                                decoration:
                                                    isTask &&
                                                        event['done']
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isTask
                                                  ? const Color(
                                                      0xFF2196F3,
                                                    ).withOpacity(
                                                      0.1,
                                                    )
                                                  : const Color(
                                                      0xFF00C853,
                                                    ).withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius: BorderRadius.circular(
                                                8,
                                              ),
                                            ),
                                            child: Text(
                                              isTask
                                                  ? 'TASK'
                                                  : 'EVENT',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isTask
                                                    ? const Color(
                                                        0xFF2196F3,
                                                      )
                                                    : const Color(
                                                        0xFF00C853,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Text(
                                                event['category'] ??
                                                    'Other',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (isTask &&
                                                  event['time'] !=
                                                      null &&
                                                  event['time'].isNotEmpty) ...[
                                                const SizedBox(
                                                  width: 12,
                                                ),
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(
                                                  width: 4,
                                                ),
                                                Text(
                                                  event['time'],
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (event['description'] !=
                                                  null &&
                                              event['description'].isNotEmpty) ...[
                                            const SizedBox(
                                              height: 4,
                                            ),
                                            Text(
                                              event['description'],
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          if (isTask) ...[
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: event['done']
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    borderRadius: BorderRadius.circular(
                                                      4,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  'Status: ${event['done'] ? 'Completed' : 'Pending'}',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: event['done']
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: !isTask
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(
                                                  () {
                                                    selectedEvents.removeAt(
                                                      index,
                                                    );
                                                    _saveEvents();
                                                  },
                                                );
                                              },
                                            )
                                          : null,
                                    ),
                                  );
                                },
                          ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ], // Close children array
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
