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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              );
            }),
          ),
        ),
        child: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A2332),
        indicatorColor: const Color(0xFF1DBF73),
        surfaceTintColor: const Color(0xFF1A2332),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront, color: Colors.white),
            selectedIcon: const Icon(Icons.storefront, color: Colors.white),
            label: 'Products',
            tooltip: 'Browse Products',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            selectedIcon: const Icon(Icons.receipt_long, color: Colors.white),
            label: 'Orders',
            tooltip: 'My Orders',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings, color: Colors.white),
            selectedIcon: const Icon(Icons.settings, color: Colors.white),
            label: 'Settings',
            tooltip: 'Settings',
          ),
        ],
      ),
      ),
    );
  }
}
