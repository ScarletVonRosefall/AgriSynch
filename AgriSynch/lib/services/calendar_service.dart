import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to manage calendar');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('calendar_events');

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final docRef = await _eventsCollection.add(event.toFirestore());
    final doc = await docRef.get();
    return CalendarEvent.fromFirestore(doc);
  }

  Stream<List<CalendarEvent>> getUserEvents() {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  Stream<List<CalendarEvent>> getEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    debugPrint('Fetching events and tasks for date: $startOfDay');

    // Create a stream for regular events
    final eventStream = _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => CalendarEvent.fromFirestore(doc))
              .toList();
          debugPrint('Found ${events.length} events');
          return events;
        });

    // Create a stream for tasks
    final taskStream = _firestore
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs.where((doc) {
            final dueDate = (doc.data()['dueDate'] as Timestamp?)?.toDate();
            if (dueDate == null) return false;
            
            final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
            final compareDate = DateTime(date.year, date.month, date.day);
            return taskDate.isAtSameMomentAs(compareDate);
          }).map((doc) {
            final data = doc.data();
            return CalendarEvent(
              id: doc.id,
              title: data['title'] ?? '',
              type: 'task',
              category: data['category'] ?? 'Other',
              description: data['description'] ?? '',
              date: (data['dueDate'] as Timestamp).toDate(),
              userId: data['userId'] ?? '',
              done: data['completed'] ?? false,
              priority: data['priority']?.toLowerCase() ?? 'medium',
              isWeatherDependent: data['weatherDependent'] ?? false,
              agricultural: {
                'cropType': data['cropType'],
                'fieldLocation': data['fieldLocation'],
              },
            );
          }).toList();
          
          debugPrint('Found ${tasks.length} tasks for date $date');
          return tasks;
        });

    // Combine both streams
    return eventStream.asyncMap((events) async {
      final tasks = await taskStream.first;
      final combined = [...events, ...tasks];
      combined.sort((a, b) => a.date.compareTo(b.date));
      return combined;
    });
  }

  Stream<List<CalendarEvent>> getEventsForRange(DateTime start, DateTime end) {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  Future<void> deleteEvent(String eventId) async {
    // Check if this is a task by trying to find it in the tasks collection first
    final taskDoc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(eventId)
        .get();
    
      if (taskDoc.exists) {
      // It's a task, delete from tasks collection
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .doc(eventId)
          .delete();
      debugPrint('Deleted task: $eventId');
    } else {
      // It's a calendar event, delete from calendar_events collection
      await _eventsCollection.doc(eventId).delete();
      debugPrint('Deleted calendar event: $eventId');
    }
  }

  Stream<List<CalendarEvent>> getEventsByCategory(String category) {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  Future<void> updateAgriculturalData(
      String eventId, Map<String, dynamic> agriculturalData) async {
    await _eventsCollection.doc(eventId).update({
      'agricultural': agriculturalData,
    });
  }
}