// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'AgriSynch.dart'; // Import for bottom navigation
import 'auth/AgriSynchSignUp.dart';
import 'auth/AgriSynchLogin.dart';
import 'auth/AgriSynchRecoverLocal.dart';
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

// ... other imports ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const AgriSynchApp(),
  );
}

class AgriSynchApp
    extends
        StatelessWidget {
  const AgriSynchApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'AgriSynch',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(
          0xFFF2FDE0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':
            (
              context,
            ) => const AuthWrapper(),
        '/login':
            (
              context,
            ) => const AgriSynchLoginPage(),
        '/home':
            (
              context,
            ) => const AgriSynchHome(), // Use bottom navigation version
        '/buyer':
            (
              context,
            ) => const AgriSynchBuyerHomePage(), // Ensure this route is defined
        '/recoverLocal':
            (
              context,
            ) => const AgriSynchRecoverLocal(),
        '/Storage':
            (
              context,
            ) => const StorageViewerPage(), // Add StorageViewer route
        '/customers':
            (
              context,
            ) => const AgriCustomersPage(),
        '/finances':
            (
              context,
            ) => const AgriFinances(),
        '/notifications':
            (
              context,
            ) => const AgriNotificationPage(),
        '/calendar':
            (
              context,
            ) => const AgriSynchCalendarPage(),
        '/orders':
            (
              context,
            ) => const AgriSynchOrdersPage(),
        '/production':
            (
              context,
            ) => const AgriSynchProductionLog(),
        '/recover':
            (
              context,
            ) => const AgriSynchRecoverPage(),
        '/settings':
            (
              context,
            ) => const AgriSynchSettingsPage(),
        '/tasks':
            (
              context,
            ) => const AgriSynchTasksPage(),
        '/verify':
            (
              context,
            ) => const AgriSynchEmailVerificationPage(),
        '/weather':
            (
              context,
            ) => const AgriWeatherPage(),
        '/browse':
            (
              context,
            ) => const BrowseProductsPage(),
        '/changePassword':
            (
              context,
            ) => const ChangePasswordPage(),
        '/help':
            (
              context,
            ) => const HelpFeedbackPage(),
        '/myOrders':
            (
              context,
            ) => const MyOrdersPage(),
        // Note: ProductDetailsPage requires parameters so cannot be added to static routes
        '/profile':
            (
              context,
            ) => const ProfilePage(),
        // ... other routes
      },
    );
  }
}
