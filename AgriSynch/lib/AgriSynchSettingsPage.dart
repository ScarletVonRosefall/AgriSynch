import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AgriSynchHomePage.dart';
import 'AgriSynchOrdersPage.dart';

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
    extends
        State<
          AgriSynchSettingsPage
        > {
  int _currentIndex = 2;
  List<
    bool
  >
  _expanded = List.generate(
    6,
    (
      _,
    ) => false,
  );
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  String userName = '';
  String userEmail = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadPreferences();
  }

  Future<
    void
  >
  loadUserInfo() async {
    userName =
        await storage.read(
          key: 'name',
        ) ??
        '';
    userEmail =
        await storage.read(
          key: 'email',
        ) ??
        '';
    userRole =
        await storage.read(
          key: 'role',
        ) ??
        '';
    setState(
      () {},
    );
  }

  Future<
    void
  >
  loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () {
        _notificationsEnabled =
            prefs.getBool(
              'notifications',
            ) ??
            true;
        _darkModeEnabled =
            prefs.getBool(
              'dark_mode',
            ) ??
            false;
      },
    );
  }

  Future<
    void
  >
  updatePreference(
    String key,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      key,
      value,
    );
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
      body: Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              40,
              20,
              20,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(
                0xFF00C853,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                  28,
                ),
                bottomRight: Radius.circular(
                  28,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Manage account & preferences',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(
                      0.8,
                    ),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // --- Main Content ---
          Expanded(
            child: Padding(
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
                                Navigator.of(
                                  context,
                                ).pushNamedAndRemoveUntil(
                                  '/login',
                                  (
                                    route,
                                  ) => false,
                                );
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
                            updatePreference(
                              'notifications',
                              value,
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
                            updatePreference(
                              'dark_mode',
                              value,
                            );
                          },
                    ),
                  ),
                  _buildTile(
                    index: 3,
                    title: "Data & Sync",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Manage your local data and cloud sync.",
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        _actionButton(
                          "Refresh Data",
                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Data refreshed successfully.",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 4,
                    title: "Help & Feedback",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Need help? Found a bug?",
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Describe your issue or feedback...",
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _actionButton(
                            "Send",
                            onTap: () {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Feedback sent. Thank you!",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 5,
                    title: "About AgriSynch",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "AgriSynch v1.0.0",
                        ),
                        Text(
                          "Developed by Team AgriSynch",
                        ),
                        Text(
                          "© 2025 All rights reserved.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          Expanded(
            child: Text(
              value,
            ),
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
