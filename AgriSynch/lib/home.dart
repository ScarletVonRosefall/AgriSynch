import 'package:flutter/material.dart';

// MainNavigationPage for bottom navigation
class MainNavigationPage
    extends
        StatefulWidget {
  const MainNavigationPage({
    Key? key,
  }) : super(
         key: key,
       );

  @override
  State<
    MainNavigationPage
  >
  createState() => _MainNavigationPageState();
}

class _MainNavigationPageState
    extends
        State<
          MainNavigationPage
        > {
  int _selectedIndex = 0;

  static const List<
    Widget
  >
  _pages =
      <
        Widget
      >[
        Center(
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Center(
          child: Text(
            'Tools',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Center(
          child: Text(
            'Orders',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Center(
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ];

  void _onItemTapped(
    int index,
  ) {
    setState(
      () {
        _selectedIndex = index;
      },
    );
  }

  bool _isDarkMode = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = _isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(
              0xFF388E3C,
            ),
            scaffoldBackgroundColor: const Color(
              0xFF232D23,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF2E473B,
              ),
              foregroundColor: Colors.white,
              elevation: 2,
              iconTheme: IconThemeData(
                color: Color(
                  0xFFB2FF59,
                ),
              ),
              titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(
                  0xFFB2FF59,
                ),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(
                0xFF232D23,
              ),
              selectedItemColor: Color(
                0xFFB2FF59,
              ),
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                color: Colors.white.withOpacity(
                  0.95,
                ),
                fontFamily: 'Poppins',
              ),
              bodyLarge: TextStyle(
                color: Color(
                  0xFFB2FF59,
                ),
                fontFamily: 'Poppins',
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(
                0xFF388E3C,
              ),
              secondary: Color(
                0xFFB2FF59,
              ),
              background: Color(
                0xFF232D23,
              ),
              surface: Color(
                0xFF2E473B,
              ),
              onPrimary: Colors.white,
              onSecondary: Color(
                0xFF232D23,
              ),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(
              0xFF388E3C,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF388E3C,
              ),
              foregroundColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(
                0xFF388E3C,
              ),
              unselectedItemColor: Colors.grey,
            ),
          );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'AgriSynch',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
              ),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                setState(
                  () {
                    _isDarkMode = !_isDarkMode;
                  },
                );
              },
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.build,
              ),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.shopping_cart,
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage
    extends
        StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFFB2FF59,
              ),
              Color(
                0xFFF1F8E9,
              ),
              Color(
                0xFF81C784,
              ),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
            ),
            child:
                TweenAnimationBuilder<
                  double
                >(
                  tween: Tween(
                    begin: 0,
                    end: 1,
                  ),
                  duration: const Duration(
                    milliseconds: 700,
                  ),
                  builder:
                      (
                        context,
                        value,
                        child,
                      ) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              (1 -
                                      value) *
                                  30,
                            ),
                            child: child,
                          ),
                        );
                      },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(
                                0.18,
                              ),
                              blurRadius: 22,
                              spreadRadius: 3,
                              offset: const Offset(
                                0,
                                10,
                              ),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            16.0,
                          ),
                          child: Image.asset(
                            'assets/farmers_group.png',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (
                                  context,
                                  error,
                                  stackTrace,
                                ) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.groups,
                                      size: 60,
                                      color: Color(
                                        0xFF388E3C,
                                      ),
                                    ),
                                    Icon(
                                      Icons.eco,
                                      size: 32,
                                      color: Color(
                                        0xFF81C784,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 28,
                      ),
                      const Text(
                        "Welcome to AgriSynch!",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(
                            0xFF388E3C,
                          ),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        "A digital home for all farmers:",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      const Text(
                        "Crop growers, livestock keepers, orchardists, urban gardeners, aquaculturists, and more.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.85,
                          ),
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(
                                0.08,
                              ),
                              blurRadius: 8,
                              offset: const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Connect, learn, and grow together with tools, tips, and a supportive community.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 36,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (
                                      context,
                                    ) => const MainNavigationPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          label: const Text(
                            "Get Started",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF388E3C,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
