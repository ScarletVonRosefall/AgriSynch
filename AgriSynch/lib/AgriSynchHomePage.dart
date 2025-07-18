import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AgriSynchCalendarPage.dart';
import 'theme_helper.dart';

class AgriSynchHomePage
    extends
        StatefulWidget {
  const AgriSynchHomePage({
    super.key,
  });

  @override
  State<
    AgriSynchHomePage
  >
  createState() => _AgriSynchHomePageState();
}

class _AgriSynchHomePageState extends State<AgriSynchHomePage> {
  final storage = FlutterSecureStorage();
  String userName = '';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadTheme();
  }

  Future<void> loadUserName() async {
    userName = await storage.read(key: 'name') ?? '';
    setState(() {});
  }

  Future<void> loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/user_avatar.png'),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning${userName.isNotEmpty ? ' $userName' : ''}!",
                          style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                        ),
                        Text(
                          "Let's Get Tasks Done!",
                          style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
                  style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --- Summary Card ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Summary",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "• 2 Tasks Today",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "• Eggs Collected: 950",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "• 1 Pending Order",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.eco,
                        color: Colors.orange,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Jump Into Our Work!",
              style: ThemeHelper.getTextStyle(
                isDark: isDarkMode,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Tile List ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _homeTile(
                  icon: Icons.calendar_month,
                  title: "Calendar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgriSynchCalendarPage(),
                      ),
                    );
                  },
                ),
                _homeTile(
                  icon: Icons.attach_money,
                  title: "Finances",
                ),
                _homeTile(
                  icon: Icons.engineering,
                  title: "Production Log",
                ),
                _homeTile(
                  icon: Icons.people_alt,
                  title: "Customers",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }
}
