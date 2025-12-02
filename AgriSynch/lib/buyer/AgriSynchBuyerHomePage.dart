import 'package:flutter/material.dart';
import '../shared/theme_helper.dart';
import 'BrowseProductsPage.dart';
import 'MyOrdersPage.dart';

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
    final isDarkMode = _themeNotifier.isDarkMode;

    final pages = const <Widget>[
      BrowseProductsPage(),
      MyOrdersPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontFamily: 'Poppins')),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : null,
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'My Orders'),
        ],
      ),
    );
  }
}
