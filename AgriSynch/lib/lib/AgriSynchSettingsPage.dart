import 'package:flutter/material.dart';
import 'AgriSynchHomePage.dart'; // Replace with your actual page files
import 'AgriSynchOrdersPage.dart';
import 'AgriSynchSettingsPage.dart'; // This file itself
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class AgriSynchSettingsPage
    extends
        StatefulWidget {
  const AgriSynchSettingsPage({
    super.key,
  });

  @override
  State<
    AgriSynchSettingsPage
  >
  createState() => _AgriSynchSettingsPageState();
}

class _AgriSynchSettingsPageState
    extends State<AgriSynchSettingsPage> {
  int _currentIndex = 2; // Settings tab
  List<bool> _expanded = List.generate(6, (_) => false);
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // User info variables
  String userName = '';
  String userEmail = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    userName = await storage.read(key: 'name') ?? '';
    userEmail = await storage.read(key: 'email') ?? '';
    userRole = await storage.read(key: 'role') ?? '';
    setState(() {});
  }
  void _onTabTapped(
    int index,
  ) {
    if (index ==
        _currentIndex)
      return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (
                  context,
                ) => const AgriSynchHomePage(),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (
                  context,
                ) => const AgriSynchOrdersPage(),
          ),
        );
        break;
      case 2:
        // Already on settings
        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF2FBE0,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF00C853,
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Text(
              'Manage account & preferences',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: ListView(
          children: [
            _buildTile(
              index: 0,
              title: "Account Settings",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Profile Information:",
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _infoRow(
                    "Name:",
                    userName,
                  ),
                  _infoRow(
                    "Email:",
                    userEmail,
                  ),
                  _infoRow(
                    "Role:",
                    userRole,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      _actionButton(
                        "Change Password",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/recover',
                          );
                        },
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      _actionButton(
                        "Log Out",
                        onTap: () {
                           Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildTile(
              index: 1,
              title: "Notifications",
              child: SwitchListTile(
                title: const Text(
                  "Enable Notifications",
                ),
                value: _notificationsEnabled,
                onChanged:
                    (
                      value,
                    ) {
                      setState(
                        () {
                          _notificationsEnabled = value;
                        },
                      );
                    },
              ),
            ),
            _buildTile(
              index: 2,
              title: "System Preferences",
              child: SwitchListTile(
                title: const Text(
                  "Dark Mode",
                ),
                value: _darkModeEnabled,
                onChanged:
                    (
                      value,
                    ) {
                      setState(
                        () {
                          _darkModeEnabled = value;
                        },
                      );
                    },
              ),
            ),
            _buildTile(
              index: 3,
              title: "Data & Sync",
            ),
            _buildTile(
              index: 4,
              title: "Help & Feedback",
            ),
            _buildTile(
              index: 5,
              title: "About AgriSynch",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required int index,
    required String title,
    Widget? child,
  }) {
    return Card(
      color: const Color(
        0xFFC5E1A5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: ExpansionTile(
        backgroundColor: const Color(
          0xFFC5E1A5,
        ),
        collapsedBackgroundColor: const Color(
          0xFFC5E1A5,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        initiallyExpanded: _expanded[index],
        onExpansionChanged:
            (
              val,
            ) {
              setState(
                () {
                  _expanded[index] = val;
                },
              );
            },
        children:
            child !=
                null
            ? [
                Padding(
                  padding: const EdgeInsets.all(
                    12,
                  ),
                  child: child,
                ),
              ]
            : [],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            value,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label, {
    VoidCallback? onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(
          0xFFDCE775,
        ),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            8,
          ),
        ),
      ),
      onPressed:
          onTap ??
          () {},
      child: Text(
        label,
      ),
    );
  }
}
