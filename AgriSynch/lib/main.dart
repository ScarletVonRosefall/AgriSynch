// lib/main.dart
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/error_handler.dart';
import 'services/notification_service.dart';
import 'AgriSynch.dart'; // Import for bottom navigation
import 'auth/AgriSynchLogin.dart';
import 'buyer/AgriSynchBuyerHomePage.dart'; // Import the Buyer Page
import 'shared/StorageViewer.dart'; // Import StorageViewer
import 'farmer/AgriCustomersPage.dart';
import 'farmer/AgriFinances.dart';
import 'shared/AgriNotificationPage.dart';
import 'farmer/AgriSynchCalendarPage.dart';
import 'farmer/AgriSynchOrdersPage.dart';
import 'farmer/AgriSynchProductionLogPage.dart';
import 'auth/AgriSynchRecover.dart';
import 'farmer/AgriSynchSettingsPage.dart';
import 'farmer/AgriSynchTasksPage.dart';
import 'auth/AgriSynchVerify.dart';
import 'shared/AgriWeatherPage.dart';
import 'buyer/BrowseProductsPage.dart';
import 'shared/change_password_page.dart';
import 'shared/HelpFeedbackPage.dart';
import 'buyer/MyOrdersPage.dart';
import 'shared/profile_page.dart';
import 'auth/auth_wrapper.dart';
import 'auth/AgriSynchSignUp.dart';
import 'admin/admin_portal.dart';
import 'admin/admin_dashboard.dart';

// ... other imports ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Crashlytics (only on mobile platforms)
  if (!kIsWeb) {
    await ErrorHandler.initializeCrashlytics();
    
    // Initialize Firebase Cloud Messaging background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Initialize Notification Service (only on mobile)
    await NotificationService().initialize();
  }
  
  runApp(const AgriSynchApp());
}

class AgriSynchApp extends StatelessWidget {
  const AgriSynchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSynch',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF2FDE0),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const AgriSynchLoginPage(),
        '/signup': (context) => const AgriSynchSignUpPage(),
        '/home': (context) =>
            const AgriSynchHome(), // Use bottom navigation version
        '/buyer-home': (context) =>
            const AgriSynchBuyerHomePage(), // Buyer home page route
        '/Storage': (context) =>
            const StorageViewerPage(), // Add StorageViewer route
        '/customers': (context) => const AgriCustomersPage(),
        '/finances': (context) => const AgriFinances(),
        '/notifications': (context) => const AgriNotificationPage(),
        '/calendar': (context) => const AgriSynchCalendarPage(),
        '/orders': (context) => const AgriSynchOrdersPage(),
        '/production': (context) => const AgriSynchProductionLog(),
        '/recover': (context) => const AgriSynchRecoverPage(),
        '/settings': (context) => const AgriSynchSettingsPage(),
        '/tasks': (context) => const AgriSynchTasksPage(),
        '/verify': (context) => AgriSynchEmailVerificationPage(
          email: ModalRoute.of(context)?.settings.arguments as String?,
        ),
        '/weather': (context) => const AgriWeatherPage(),
        '/browse': (context) => const BrowseProductsPage(),
        '/changePassword': (context) => const ChangePasswordPage(),
        '/help': (context) => const HelpFeedbackPage(),
        '/myOrders': (context) => const MyOrdersPage(),
        // Note: ProductDetailsPage requires parameters so cannot be added to static routes
        '/profile': (context) => const ProfilePage(),
        '/admin-portal': (context) => const AdminPortalPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        // ... other routes
      },
    );
  }
}
