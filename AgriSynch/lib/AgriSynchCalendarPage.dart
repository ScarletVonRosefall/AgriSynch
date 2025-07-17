import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      String
    >
  >
  _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
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
          _events =
              Map<
                String,
                List<
                  String
                >
              >.from(
                json.decode(
                  storedData,
                ),
              );
        },
      );
    }
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

  void _addEvent(
    String event,
  ) {
    final key = _selectedDay!.toIso8601String().split(
      'T',
    )[0];
    if (_events[key] ==
        null) {
      _events[key] = [];
    }
    _events[key]!.add(
      event,
    );
    _saveEvents();
    setState(
      () {},
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (
            _,
          ) => AlertDialog(
            title: const Text(
              'Add Event',
            ),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter event',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    _addEvent(
                      controller.text.trim(),
                    );
                  }
                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'Save',
                ),
              ),
            ],
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
      appBar: AppBar(
        title: const Text(
          'Calendar',
        ),
        backgroundColor: const Color(
          0xFF00C853,
        ),
      ),
      backgroundColor: const Color(
        0xFFF2FDE0,
      ),
      body: Column(
        children: [
          TableCalendar(
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
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
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
          const SizedBox(
            height: 10,
          ),
          if (_selectedDay !=
              null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF00C853,
                ),
              ),
              onPressed: _showAddDialog,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Add Event',
              ),
            ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedEvents.length,
              itemBuilder:
                  (
                    _,
                    index,
                  ) {
                    return ListTile(
                      title: Text(
                        selectedEvents[index],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                        ),
                        onPressed: () {
                          selectedEvents.removeAt(
                            index,
                          );
                          _saveEvents();
                          setState(
                            () {},
                          );
                        },
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
