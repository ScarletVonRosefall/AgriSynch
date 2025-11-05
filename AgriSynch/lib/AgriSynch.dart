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
import 'buyer/AgriSynchBuyerSettingsPage.dart';
import 'shared/conversations_list_page.dart';
import 'services/chat_service.dart';
import 'shared/theme_helper.dart';

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
        '/buyer-home': (context) => const AgriSynchBuyerHome(),
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
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  final List<Widget> pages = const [
    AgriSynchHomePage(),
    AgriSynchTasksPage(),
    AgriSynchProductsPage(),
    AgriSynchOrdersPage(),
    ConversationsListPage(showBackButton: false),
    AgriSynchSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDarkMode ? const Color(0xFF1B5E20) : Colors.white,
        selectedItemColor: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        unselectedItemColor: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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

class AgriSynchBuyerHome extends StatefulWidget {
  const AgriSynchBuyerHome({super.key});

  @override
  State<AgriSynchBuyerHome> createState() => _AgriSynchBuyerHomeState();
}

class _AgriSynchBuyerHomeState extends State<AgriSynchBuyerHome> {
  int _currentIndex = 0;
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  final List<Widget> pages = const [
    AgriSynchBuyerHomePage(),
    ConversationsListPage(showBackButton: false),
    AgriSynchBuyerSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1B5E20) : Colors.white,
        selectedItemColor: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        unselectedItemColor: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
        elevation: 8,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
