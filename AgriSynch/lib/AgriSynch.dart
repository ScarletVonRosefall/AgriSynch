// If you're reading this we dont know how we made this functional but please
// Don't change anything unless you really know what you're doing.
// And sorry for our poor coding practices and any confusion it may have caused.
// You're on your own now, ADIOS!

// ps. don't run this on debug mode or you'll be met with the white screen of death.

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
import 'shared/conversations_list_page.dart';
import 'services/chat_service.dart';

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
    ConversationsListPage(),
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Products"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: ChatService.getUnreadCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    const Icon(Icons.message),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: "Messages",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
