import 'package:flutter/material.dart';
import '../shared/theme_helper.dart';
import 'BrowseProductsPage.dart';
import 'MyOrdersPage.dart';
import 'AgriSynchBuyerSettingsPage.dart';

class AgriSynchBuyerHomePage extends StatefulWidget {
  const AgriSynchBuyerHomePage({super.key});

  @override
  State<AgriSynchBuyerHomePage> createState() => _AgriSynchBuyerHomePageState();
}

class _AgriSynchBuyerHomePageState extends State<AgriSynchBuyerHomePage> {
  final _themeNotifier = ThemeNotifier();
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final pages = const <Widget>[
      BrowseProductsPage(),
      MyOrdersPage(),
      AgriSynchBuyerSettingsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'AgriSynch Marketplace',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2332),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A2332),
        indicatorColor: const Color(0xFF1DBF73),
        surfaceTintColor: const Color(0xFF1A2332),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront),
            label: 'Products',
            tooltip: 'Browse Products',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: 'Orders',
            tooltip: 'My Orders',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}
