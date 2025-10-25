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
    this.agricultural,
  });

  // Convert Firestore document to CalendarEvent object
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
      agricultural: data['agricultural'],
    );
  }

  // Convert CalendarEvent object to JSON for Firestore
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
      'agricultural': agricultural ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of this event with some fields updated
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