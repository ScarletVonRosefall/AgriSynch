import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
/// Manages token registration, notification display, and message handling
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get notificationTapStream => 
      _notificationTapController.stream;

  bool _initialized = false;

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('✅ User granted notification permission');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          debugPrint('⚠️ User granted provisional notification permission');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ User declined or has not accepted notification permission');
        }
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        if (kDebugMode) {
          debugPrint('📱 FCM Token: $token');
        }
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      _initialized = true;
      if (kDebugMode) {
        debugPrint('✅ NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing NotificationService: $e');
      }
    }
  }

  /// Initialize local notifications for displaying in-app notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'agrisynch_orders', // id
      'Order Updates', // name
      description: 'Notifications for order status updates and new orders',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Save FCM token to Firestore for the current user
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          debugPrint('✅ FCM token saved for user: ${user.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving FCM token: $e');
      }
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📬 Foreground message received: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
    }

    // Show local notification
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  /// Handle notification taps from background/terminated state
  void _handleBackgroundMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('🔔 Notification tapped: ${message.messageId}');
      debugPrint('Data: ${message.data}');
    }

    // Emit tap event for navigation
    _notificationTapController.add(message.data);
  }

  /// Handle local notification taps
  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('🔔 Local notification tapped: ${response.payload}');
    }

    // Parse payload and emit tap event
    if (response.payload != null) {
      try {
        // Payload format: "type:orderId" or similar
        final parts = response.payload!.split(':');
        if (parts.length == 2) {
          _notificationTapController.add({
            'type': parts[0],
            'id': parts[1],
          });
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agrisynch_orders',
      'Order Updates',
      channelDescription: 'Notifications for order status updates and new orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload from message data
    String? payload;
    if (message.data.containsKey('type') && message.data.containsKey('orderId')) {
      payload = '${message.data['type']}:${message.data['orderId']}';
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,
    );
  }

  /// Show a local notification directly (without Cloud Functions)
  /// Use this for Spark Plan - shows notification on the current device
  Future<void> showLocalNotificationDirect({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agrisynch_orders',
      'Order Updates',
      channelDescription: 'Notifications for order status updates and new orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('📱 Local notification shown: $title');
    }
  }

  /// Send a notification to a specific user
  /// This would typically be called from your backend/Cloud Functions
  /// For demo purposes, we'll store it in Firestore to trigger via Cloud Functions
  Future<void> sendOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    required String status,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        if (kDebugMode) {
            debugPrint('⚠️ No FCM token found for user: $userId');
          }
        return;
      }

      // Store notification in Firestore for Cloud Functions to process
      // In production, you'd have a Cloud Function that reads this and sends via FCM
      await _firestore.collection('notifications').add({
        'userId': userId,
        'orderId': orderId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'type': 'order',
          'orderId': orderId,
          'status': status,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      if (kDebugMode) {
        debugPrint('✅ Notification queued for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notification: $e');
      }
    }
  }

  /// Send notification when order status changes (for buyers)
  Future<void> notifyBuyerOrderStatusChange({
    required String buyerId,
    required String orderId,
    required String productName,
    required String newStatus,
  }) async {
    String title = '';
    String body = '';

    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        title = '✅ Order Confirmed';
        body = 'Your order for $productName has been confirmed!';
        break;
      case 'preparing':
        title = '📦 Order Preparing';
        body = 'The farmer is preparing your order for $productName.';
        break;
      case 'ready':
        title = '✨ Order Ready';
        body = 'Your order for $productName is ready for pickup/delivery!';
        break;
      case 'in transit':
        title = '🚚 Order In Transit';
        body = 'Your order for $productName is on its way!';
        break;
      case 'delivered':
        title = '🎉 Order Delivered';
        body = 'Your order for $productName has been delivered!';
        break;
      case 'cancelled':
        title = '❌ Order Cancelled';
        body = 'Your order for $productName has been cancelled.';
        break;
      default:
        title = '📬 Order Update';
        body = 'Status changed to: $newStatus';
    }

    await sendOrderNotification(
      userId: buyerId,
      orderId: orderId,
      title: title,
      body: body,
      status: newStatus,
    );
  }

  /// Send notification for new order (for farmers)
  Future<void> notifyFarmerNewOrder({
    required String farmerId,
    required String orderId,
    required String productName,
    required String buyerName,
    required double totalAmount,
  }) async {
    await sendOrderNotification(
      userId: farmerId,
      orderId: orderId,
      title: '🔔 New Order Received!',
      body: '$buyerName ordered $productName (₱${totalAmount.toStringAsFixed(2)})',
      status: 'pending',
    );
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📬 Background message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
  }
}
