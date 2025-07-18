import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'AgriSynchCalendarPage.dart'; // Make sure this import exists

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

class _AgriSynchHomePageState
    extends
        State<
          AgriSynchHomePage
        > {

          final storage = FlutterSecureStorage();
  String userName = '';

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    userName = await storage.read(key: 'name') ?? '';
    setState(() {});
  }
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF2FDE0,
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
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage(
                        'assets/user_avatar.png',
                      ),
                      radius: 20,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning${userName.isNotEmpty ? ' $userName' : ''}!",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Let's Get Tasks Done!",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 13,
                          ),
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
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        width: 8,
                      ),
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

          const SizedBox(
            height: 14,
          ),

          // --- Summary Card ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF00E676,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Summary",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: 6,
                        ),
                        Text(
                          "• 2 Tasks Today",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "• Eggs Collected: 950",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "• 1 Pending Order",
                          style: TextStyle(
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

          const SizedBox(
            height: 20,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              "Jump Into Our Work!",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // --- Tile List ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              children: [
                _homeTile(
                  icon: Icons.calendar_month,
                  title: "Calendar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (
                              _,
                            ) => const AgriSynchCalendarPage(),
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
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      elevation: 2,
      color: const Color(
        0xFF4CAF50,
      ),
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
