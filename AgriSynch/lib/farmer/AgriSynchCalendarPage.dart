import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/calendar_service.dart';
import '../models/calendar_event.dart';
import '../models/agricultural_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgriSynchCalendarPage extends StatefulWidget {
  const AgriSynchCalendarPage({super.key});

  @override
  State<AgriSynchCalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<AgriSynchCalendarPage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarService _calendarService = CalendarService();
  List<CalendarEvent> _currentEvents = [];
  bool isDarkMode = false;
  int unreadNotifications = 0;
  Stream<List<CalendarEvent>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    await _loadTheme();
    await _loadUnreadNotifications();
    _initializeEventsStream();
  }

  void _initializeEventsStream() {
    if (_selectedDay != null) {
      setState(() {
        _eventsStream = _calendarService.getEventsForDate(_selectedDay!);
      });
    }
  }

  Future<void> _loadTheme() async {
    final darkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {
      isDarkMode = darkMode;
    });
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationHelper.getUnreadCount();
    setState(() {
      unreadNotifications = count;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _currentEvents.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  Future<void> _addEvent(String title, String category, String description, {AgriculturalData? agriculturalData}) async {
    if (_selectedDay == null) return;

    try {
      final event = CalendarEvent(
        id: '', // Will be set by Firestore
        title: title,
        type: 'event',
        category: category,
        description: description,
        date: _selectedDay!,
        userId: FirebaseAuth.instance.currentUser!.uid,
        agricultural: agriculturalData?.toMap(),
      );

      await _calendarService.createEvent(event);

      NotificationHelper.addNotification(
        title: 'Calendar Event Added',
        message: 'Event "$title" has been scheduled successfully!',
        type: 'system',
      );
      _loadUnreadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Other';

    // Agricultural specific controllers
    final cropTypeController = TextEditingController();
    final fieldLocationController = TextEditingController();
    final expectedYieldController = TextEditingController();
    final weatherDependencyController = TextEditingController();

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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Add Farm Event',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (selectedCategory == 'Harvesting') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Harvest Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cropTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Crop Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fieldLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Field Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: expectedYieldController,
                    decoration: const InputDecoration(
                      labelText: 'Expected Yield (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weatherDependencyController,
                    decoration: const InputDecoration(
                      labelText: 'Weather Requirements',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an event title')),
                  );
                  return;
                }

                AgriculturalData? agriculturalData;
                if (selectedCategory == 'Harvesting') {
                  agriculturalData = AgriculturalData(
                    cropType: cropTypeController.text.trim(),
                    fieldLocation: fieldLocationController.text.trim(),
                    expectedYield: double.tryParse(expectedYieldController.text.trim()),
                    weatherDependency: weatherDependencyController.text.trim(),
                  );
                }

                _addEvent(
                  titleController.text.trim(),
                  selectedCategory,
                  descriptionController.text.trim(),
                  agriculturalData: agriculturalData,
                );

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Farm Calendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AgriNotificationPage(),
                          ),
                        ).then((_) => _loadUnreadNotifications());
                      },
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications, color: Colors.white),
                          if (unreadNotifications > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$unreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar and Events
          Expanded(
            child: StreamBuilder<List<CalendarEvent>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                _currentEvents = snapshot.data ?? [];

                return Column(
                  children: [
                    TableCalendar<CalendarEvent>(
                      firstDay: DateTime.utc(2020),
                      lastDay: DateTime.utc(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: _getEventsForDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _eventsStream = _calendarService.getEventsForDate(selectedDay);
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Selected Date Events
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getEventsForDay(_selectedDay ?? _focusedDay).length,
                        itemBuilder: (context, index) {
                          final event = _getEventsForDay(_selectedDay ?? _focusedDay)[index];
                          return Dismissible(
                            key: Key(event.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              try {
                                await _calendarService.deleteEvent(event.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Event deleted')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete event: $e')),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(event.category),
                                    if (event.description.isNotEmpty)
                                      Text(event.description),
                                    if (event.agricultural != null) ...[
                                      const Divider(),
                                      Text(
                                        'Crop: ${event.agricultural!['cropType']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Field: ${event.agricultural!['fieldLocation']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (event.agricultural!['expectedYield'] != null)
                                        Text(
                                          'Expected Yield: ${event.agricultural!['expectedYield']} kg',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add),
      ),
    );
  }
}