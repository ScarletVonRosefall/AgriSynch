// lib/main.dart
import 'package:flutter/material.dart';
import 'AgriSynch.dart'; // Import for bottom navigation
import 'AgriSynchSignUp.dart';
import 'AgriSynchLogin.dart';
import 'AgriSynchRecoverLocal.dart';
import 'AgriSynchBuyerPage.dart'; // Import the new Buyer Page
import 'StorageViewer.dart'; // Import StorageViewer
import 'AgriCustomersPage.dart';
import 'AgriFinances.dart';
import 'AgriNotificationPage.dart';
import 'AgriSynchCalendarPage.dart';
import 'AgriSynchOrdersPage.dart';
import 'AgriSynchProductionLogPage.dart';
import 'AgriSynchRecover.dart';
import 'AgriSynchSettingsPage.dart';
import 'AgriSynchTasksPage.dart';
import 'AgriSynchVerify.dart';
import 'AgriWeatherPage.dart';
import 'BrowseProductsPage.dart';
import 'change_password_page.dart';
import 'HelpFeedbackPage.dart';
import 'MyOrdersPage.dart';
import 'profile_page.dart';

// ... other imports ...

void
main() {
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
            ) => const AgriSynchSignUpPage(),
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
            ) => const AgriSynchBuyerPage(), // Ensure this route is defined
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
