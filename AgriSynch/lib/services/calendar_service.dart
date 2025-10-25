import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID or throw error if not logged in
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to manage calendar');
    return user.uid;
  }

  // Get reference to events collection
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('calendar_events');

  // Create a new calendar event
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final docRef = await _eventsCollection.add(event.toFirestore());
    final doc = await docRef.get();
    return CalendarEvent.fromFirestore(doc);
  }

  // Get all events for current user
  Stream<List<CalendarEvent>> getUserEvents() {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  // Get events for a specific date
  Stream<List<CalendarEvent>> getEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  // Update an existing event
  Future<void> updateEvent(CalendarEvent event) async {
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }

  // Get events for a date range (useful for month view)
  Stream<List<CalendarEvent>> getEventsForRange(
    DateTime start,
    DateTime end,
  ) {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  // Mark a task as complete/incomplete
  Future<void> toggleTaskCompletion(String eventId, bool isDone) async {
    await _eventsCollection.doc(eventId).update({'done': isDone});
  }

  // Get all events in a specific category
  Stream<List<CalendarEvent>> getEventsByCategory(String category) {
    return _eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }

  // Add or update agricultural data for an event
  Future<void> updateAgriculturalData(
    String eventId,
    Map<String, dynamic> agriculturalData,
  ) async {
    await _eventsCollection.doc(eventId).update({
      'agricultural': agriculturalData,
    });
  }
}