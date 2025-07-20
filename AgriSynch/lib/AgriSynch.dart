import 'package:flutter/material.dart';
import 'AgriSynchHomePage.dart';
import 'AgriSynchTasksPage.dart';
import 'AgriSynchOrdersPage.dart';
import 'AgriSynchSettingsPage.dart';
import 'AgriSynchSignUp.dart';
import 'AgriSynchLogin.dart';
//import 'AgriSynchRecover.dart';
import 'AgriSynchRecoverLocal.dart';
import 'StorageViewer.dart';

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
            ) => const AgriSynchHome(),
        '/storage':
            (
              context,
            ) => const StorageViewerPage(),
        '/recover':
            (
              context,
            ) => const AgriSynchRecoverLocal(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AgriSynchHome
    extends
        StatefulWidget {
  const AgriSynchHome({
    super.key,
  });

  @override
  State<
    AgriSynchHome
  >
  createState() => _AgriSynchHomeState();
}

class _AgriSynchHomeState
    extends
        State<
          AgriSynchHome
        > {
  int _currentIndex = 0;

  final List<
    Widget
  >
  pages = const [
    AgriSynchHomePage(),
    AgriSynchTasksPage(),
    AgriSynchOrdersPage(),
    AgriSynchSettingsPage(),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap:
            (
              index,
            ) {
              setState(
                () {
                  _currentIndex = index;
                },
              );
            },
        selectedItemColor: const Color(
          0xFF00C853,
        ),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.task,
            ),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_cart,
            ),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
