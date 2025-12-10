import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String type;
  final String category;
  final String description;
  final DateTime date;
  final String userId;
  final String? time;
  final bool? done;
  final String priority; // high, medium, low
  final Map<String, dynamic>? recurrence; // For repeating events
  final bool? isWeatherDependent;
  final List<String>? linkedItemIds; // For linked tasks or orders
  final Map<String, dynamic>? agricultural;  // For crop-specific data

  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.userId,
    this.time,
    this.done = false,
    this.priority = 'medium',
    this.recurrence,
    this.isWeatherDependent = false,
    this.linkedItemIds = const [],
    this.agricultural,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'event',
      category: data['category'] ?? 'Other',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      time: data['time'],
      done: data['done'] ?? false,
      priority: data['priority'] ?? 'medium',
      recurrence: data['recurrence'],
      isWeatherDependent: data['isWeatherDependent'] ?? false,
      linkedItemIds: List<String>.from(data['linkedItemIds'] ?? []),
      agricultural: data['agricultural'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'time': time,
      'done': done,
      'priority': priority,
      'recurrence': recurrence,
      'isWeatherDependent': isWeatherDependent,
      'linkedItemIds': linkedItemIds,
      'agricultural': agricultural ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  CalendarEvent copyWith({
    String? title,
    String? type,
    String? category,
    String? description,
    DateTime? date,
    String? time,
    bool? done,
    Map<String, dynamic>? agricultural,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId,
      time: time ?? this.time,
      done: done ?? this.done,
      agricultural: agricultural ?? this.agricultural,
    );
  }
}