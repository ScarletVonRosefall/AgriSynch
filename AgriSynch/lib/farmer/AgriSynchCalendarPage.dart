import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/calendar_service.dart';
import '../models/calendar_event.dart';
import '../models/agricultural_data.dart';
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
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  Stream<List<CalendarEvent>>? _eventsStream;

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Planting':
        return const Color(0xFF4CAF50); // Green
      case 'Harvesting':
        return const Color(0xFFFF9800); // Orange
      case 'Fertilizing':
        return const Color(0xFF8BC34A); // Light Green
      case 'Pest Control':
        return const Color(0xFFF44336); // Red
      case 'Irrigation':
        return const Color(0xFF2196F3); // Blue
      case 'Feeding':
        return const Color(0xFFFFEB3B); // Yellow
      case 'Maintenance':
        return const Color(0xFF9C27B0); // Purple
      case 'Health Check':
        return const Color(0xFFE91E63); // Pink
      case 'Inventory':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Dark Grey
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Planting':
        return Icons.grass;
      case 'Harvesting':
        return Icons.agriculture;
      case 'Fertilizing':
        return Icons.water_drop;
      case 'Pest Control':
        return Icons.bug_report;
      case 'Irrigation':
        return Icons.water;
      case 'Feeding':
        return Icons.lunch_dining;
      case 'Maintenance':
        return Icons.build;
      case 'Health Check':
        return Icons.healing;
      case 'Inventory':
        return Icons.inventory;
      default:
        return Icons.event;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _initializeCalendar();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _initializeCalendar() async {
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
    final isDarkMode = _themeNotifier.isDarkMode;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    // Agricultural specific controllers
    final cropTypeController = TextEditingController();
    final fieldLocationController = TextEditingController();
    final expectedYieldController = TextEditingController();
    final weatherDependencyController = TextEditingController();

    var selectedCategory = 'Planting'; // Default to Planting for farmers

    final categories = [
      'Planting',
      'Harvesting',
      'Fertilizing',
      'Pest Control',
      'Irrigation',
      'Feeding',
      'Maintenance',
      'Health Check',
      'Inventory',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF263238) : Colors.white,
          title: Text(
            'Add Farm Event',
            style: TextStyle(
              fontFamily: 'Poppins', 
              fontWeight: FontWeight.bold,
              color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    labelStyle: TextStyle(
                      color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  dropdownColor: isDarkMode ? const Color(0xFF263238) : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                      ),
                    ),
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
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                      color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Show crop and field for all agricultural categories
                if (selectedCategory == 'Planting' ||
                    selectedCategory == 'Harvesting' ||
                    selectedCategory == 'Fertilizing' ||
                    selectedCategory == 'Pest Control' ||
                    selectedCategory == 'Irrigation') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    '$selectedCategory Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cropTypeController,
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Crop Type',
                      labelStyle: TextStyle(
                        color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fieldLocationController,
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Field Location',
                      labelStyle: TextStyle(
                        color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Additional fields specific to Harvesting
                  if (selectedCategory == 'Harvesting') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: expectedYieldController,
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Expected Yield (kg)',
                        labelStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                          ),
                        ),
                        hintText: '1000',
                        hintStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF757575) : Colors.grey[400],
                        ),
                        helperText: 'Enter harvest amount in kg (e.g., 1000 for 1 ton)',
                        helperStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                        ),
                        suffixText: 'kg',
                        suffixStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                  // Weather dependency for weather-sensitive activities
                  if (selectedCategory == 'Planting' ||
                      selectedCategory == 'Harvesting' ||
                      selectedCategory == 'Irrigation') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: weatherDependencyController,
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Weather Requirements',
                        labelStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode ? const Color(0xFF616161) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF00C853),
              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an event title')),
                  );
                  return;
                }

                AgriculturalData? agriculturalData;
                if (selectedCategory == 'Planting' ||
                    selectedCategory == 'Harvesting' ||
                    selectedCategory == 'Fertilizing' ||
                    selectedCategory == 'Pest Control' ||
                    selectedCategory == 'Irrigation') {
                  agriculturalData = AgriculturalData(
                    cropType: cropTypeController.text.trim(),
                    fieldLocation: fieldLocationController.text.trim(),
                    expectedYield: selectedCategory == 'Harvesting' 
                        ? double.tryParse(expectedYieldController.text.trim())
                        : null,
                    weatherDependency: (selectedCategory == 'Planting' ||
                            selectedCategory == 'Harvesting' ||
                            selectedCategory == 'Irrigation')
                        ? weatherDependencyController.text.trim()
                        : null,
                    plantingDate: selectedCategory == 'Planting' 
                        ? _selectedDay 
                        : null,
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
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
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                        // Text styles for better dark mode contrast
                        defaultTextStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                        ),
                        weekendTextStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                        ),
                        outsideTextStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF757575) : Colors.grey[400],
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        todayTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
                        ),
                        weekendStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[700],
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
                                if (!mounted) return;
                                
                                // Refresh the events for the selected day
                                setState(() {
                                  _eventsStream = _calendarService.getEventsForDate(_selectedDay ?? _focusedDay);
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${event.type == 'task' ? 'Task' : 'Event'} deleted')),
                                );
                              } catch (e) {
                                print('Error deleting event: $e');
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete ${event.type}: $e')),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: getCategoryColor(event.category),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: getCategoryColor(event.category).withAlpha((0.2 * 255).round()),
                                    child: Icon(
                                      _getCategoryIcon(event.category),
                                      color: getCategoryColor(event.category),
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        // Show confirmation dialog
                                        if (!context.mounted) return;
                                        
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: Text('Delete ${event.type == 'task' ? 'Task' : 'Event'}?'),
                                            content: Text(event.type == 'task' 
                                                ? 'This will delete the task from your task list.'
                                                : 'This action cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(dialogContext);
                                                  try {
                                                    await _calendarService.deleteEvent(event.id);
                                                    if (!context.mounted) return;
                                                    
                                                    // Refresh the events for the selected day
                                                    setState(() {
                                                      _eventsStream = _calendarService.getEventsForDate(_selectedDay ?? _focusedDay);
                                                    });
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('${event.type == 'task' ? 'Task' : 'Event'} deleted successfully')),
                                                    );
                                                  } catch (e) {
                                                    print('Error deleting: $e');
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to delete ${event.type}: $e')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete, color: Colors.red),
                                          title: Text('Delete Event'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.category),
                                      if (event.description.isNotEmpty)
                                        Text(event.description),
                                      if (event.agricultural != null) ...[
                                        const Divider(),
                                        if (event.agricultural!['cropType'] != null)
                                          Text(
                                            'Crop: ${event.agricultural!['cropType']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        if (event.agricultural!['fieldLocation'] != null)
                                          Text(
                                            'Field: ${event.agricultural!['fieldLocation']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        if (event.agricultural!['expectedYield'] != null)
                                          Text(
                                            'Expected Yield: ${event.agricultural!['expectedYield']} kg',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        if (event.agricultural!['weatherDependency'] != null)
                                          Text(
                                            'Weather: ${event.agricultural!['weatherDependency']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ],
                                  ),
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
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}