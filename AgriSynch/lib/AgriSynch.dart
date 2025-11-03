import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'farmer/AgriSynchHomePage.dart';
import 'farmer/AgriSynchTasksPage.dart';
import 'farmer/AgriSynchOrdersPage.dart';
import 'farmer/AgriSynchProductsPage.dart';
import 'farmer/AgriSynchSettingsPage.dart';
import 'auth/AgriSynchSignUp.dart';
import 'auth/AgriSynchLogin.dart';
import 'auth/AgriSynchRecover.dart';
import 'shared/StorageViewer.dart';
import 'buyer/AgriSynchBuyerHomePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        '/': (context) => const AgriSynchSignUpPage(),
        '/login': (context) => const AgriSynchLoginPage(),
        '/home': (context) => const AgriSynchHome(),
        '/buyer-home': (context) => const AgriSynchBuyerHomePage(),
        '/storage': (context) => const StorageViewerPage(),
        '/recover': (context) => const AgriSynchRecoverPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AgriSynchHome extends StatefulWidget {
  const AgriSynchHome({super.key});

  @override
  State<AgriSynchHome> createState() => _AgriSynchHomeState();
}

class _AgriSynchHomeState extends State<AgriSynchHome> {
  int _currentIndex = 0;

  final List<Widget> pages = const [
    AgriSynchHomePage(),
    AgriSynchTasksPage(),
    AgriSynchProductsPage(),
    AgriSynchOrdersPage(),
    AgriSynchSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF00C853),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Products"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
