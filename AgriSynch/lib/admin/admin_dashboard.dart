import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../shared/theme_helper.dart';
import '../AgriSynch.dart';
import 'admin_reports_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin, RouteAware {
  final _themeNotifier = ThemeNotifier();
  bool _isProcessing = false;
  late TabController _tabController;
  
  // Search & Filter state
  String _userSearchQuery = '';
  String _userTypeFilter = 'all';
  String _productSearchQuery = '';
  String _messageSearchQuery = '';
  String _orderStatusFilter = 'all';
  
  // Bulk Actions state
  Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Ensure admin dashboard always opens in light mode
    ThemeNotifier().resetTheme().catchError((e) {
      print('Failed to reset theme on admin open: $e');
    });
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer so we can detect when admin returns from test pages
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }
  @override
  void didPopNext() {
    // Called when a route above this one has been popped and this route shows again
    ThemeNotifier().resetTheme().catchError((e) {
      print('Failed to reset theme on return to admin dashboard: $e');
    });
    if (mounted) setState(() {});
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      // Add your logout logic here
      FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF00A862),
                title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
                centerTitle: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.science, color: Colors.white),
                    tooltip: 'Test Mode',
                    onSelected: (value) {
                      if (value == 'farmer') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AgriSynchHome()),
                        );
                      } else if (value == 'buyer') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AgriSynchBuyerHome(hideBottomNav: true)),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'farmer',
                        child: Row(
                          children: [
                            Icon(Icons.agriculture, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Test as Farmer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'buyer',
                        child: Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Test as Buyer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () => _confirmLogout(),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabAlignment: TabAlignment.start,
                    physics: const BouncingScrollPhysics(),
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                      Tab(icon: Icon(Icons.help_outline), text: 'Support'),
                      Tab(icon: Icon(Icons.flag), text: 'Reports'),
                      Tab(icon: Icon(Icons.people), text: 'Users'),
                      Tab(icon: Icon(Icons.shopping_bag), text: 'Products'),
                      Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
                      Tab(icon: Icon(Icons.message), text: 'Messages'),
                    ],
                  ),
                ),
              ),
              body: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00A862)),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildOverviewTab(),
                        _buildSupportTab(),
                        const AdminReportsPage(),
                        _buildUsersTab(),
                        _buildProductsTab(),
                        _buildOrdersTab(),
                        _buildMessagesTab(),
                      ],
                    ),
            );
          }

  // Tab 1: Overview with Analytics
  Widget _buildOverviewTab() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Overview',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 16),
          
          // Statistics Cards - Compact 3x2 Grid
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              final allDocs = usersSnapshot.data?.docs ?? [];
              final totalUsers = allDocs.length;
              final farmers = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                final accountType = data?['accountType'];
                final isAdmin = data?['isAdmin'] == true;
                return accountType == 'Farmer' && !isAdmin;
              }).length;
              final buyers = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                final accountType = data?['accountType'];
                final isAdmin = data?['isAdmin'] == true;
                return accountType == 'Buyer' && !isAdmin;
              }).length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatCard(
                          'Users',
                          totalUsers.toString(),
                          Icons.people,
                          const Color(0xFF5DADE2),
                          isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactStatCard(
                          'Farmers',
                          farmers.toString(),
                          Icons.agriculture,
                          const Color(0xFF52BE80),
                          isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactStatCard(
                          'Buyers',
                          buyers.toString(),
                          Icons.shopping_bag,
                          const Color(0xFFF39C12),
                          isDarkMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('products').snapshots(),
                          builder: (context, snapshot) {
                            final total = snapshot.data?.docs.length ?? 0;
                            return _buildCompactStatCard(
                              'Products',
                              total.toString(),
                              Icons.inventory_2,
                              const Color(0xFFAB7AC6),
                              isDarkMode,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, snapshot) {
                            final total = snapshot.data?.docs.length ?? 0;
                            return _buildCompactStatCard(
                              'Orders',
                              total.toString(),
                              Icons.receipt,
                              const Color(0xFF48C9B0),
                              isDarkMode,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('messages').snapshots(),
                          builder: (context, snapshot) {
                            final total = snapshot.data?.docs.length ?? 0;
                            return _buildCompactStatCard(
                              'Messages',
                              total.toString(),
                              Icons.message,
                              const Color(0xFFE74C3C),
                              isDarkMode,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Pending Account Action Requests Alert
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accountActionRequests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final pendingRequests = snapshot.data?.docs.length ?? 0;
              
              if (pendingRequests > 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_outlined, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Account Action Requests',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$pendingRequests request(s) awaiting review',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: Text(
                          'Review',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(isDarkMode),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.getTextColor(isDarkMode),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: ThemeHelper.getSecondaryTextColor(isDarkMode),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Tab 2: Support & Feedback
  Widget _buildSupportTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A862)),
          );
        }

        var requests = snapshot.data?.docs ?? [];
        
        // Filter out resolved and dismissed items - only show pending
        requests = requests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          return status != 'resolved' && status != 'dismissed';
        }).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending support requests',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'Anonymous';
            final userEmail = data['userEmail'] ?? 'No email provided';
            final category = data['category'] ?? 'General';
            final feedback = data['feedback'] ?? 'No message provided';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            
            Color categoryColor;
            IconData categoryIcon;
            switch (category) {
              case 'Bug Report':
                categoryColor = Colors.red;
                categoryIcon = Icons.bug_report;
                break;
              case 'Feature Request':
                categoryColor = Colors.blue;
                categoryIcon = Icons.lightbulb_outline;
                break;
              case 'Account Issues':
                categoryColor = Colors.orange;
                categoryIcon = Icons.account_circle;
                break;
              case 'Technical Support':
                categoryColor = Colors.purple;
                categoryIcon = Icons.build;
                break;
              default:
                categoryColor = Colors.green;
                categoryIcon = Icons.help_outline;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              color: ThemeHelper.getCardColor(_themeNotifier.isDarkMode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: categoryColor.withOpacity(0.3), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: categoryColor,
                          child: Icon(categoryIcon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: categoryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Message:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Submitted: ${timestamp != null ? _formatDate(timestamp) : 'Unknown'}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _resolveFeedback(request.id, 'resolved'),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Resolve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _resolveFeedback(request.id, 'dismissed'),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Dismiss'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tab 3: Users Management
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _userSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _userSearchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _userSearchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              // Filter chips with Select All
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Select All button
                      ElevatedButton.icon(
                        onPressed: _toggleSelectAllUsers,
                        icon: Icon(_selectedUserIds.isEmpty ? Icons.check_box_outline_blank : Icons.check_box),
                        label: const Text('Select All', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilterChip(
                        label: const Text('All', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                        selected: _userTypeFilter == 'all',
                        selectedColor: const Color(0xFF00A862),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        labelStyle: TextStyle(
                          color: _userTypeFilter == 'all' ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) => setState(() => _userTypeFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Farmers', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                        selected: _userTypeFilter == 'Farmer',
                        selectedColor: const Color(0xFF00A862),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        labelStyle: TextStyle(
                          color: _userTypeFilter == 'Farmer' ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) => setState(() => _userTypeFilter = 'Farmer'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Buyers', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                        selected: _userTypeFilter == 'Buyer',
                        selectedColor: const Color(0xFF00A862),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        labelStyle: TextStyle(
                          color: _userTypeFilter == 'Buyer' ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) => setState(() => _userTypeFilter = 'Buyer'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Admins', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                        selected: _userTypeFilter == 'Admin',
                        selectedColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        labelStyle: TextStyle(
                          color: _userTypeFilter == 'Admin' ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) => setState(() => _userTypeFilter = 'Admin'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bulk action bar
        if (_selectedUserIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.blue.shade200, width: 1),
                bottom: BorderSide(color: Colors.blue.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedUserIds.length} selected',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _selectedUserIds.clear()),
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Clear Selection',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _bulkBanUsers,
                  icon: const Icon(Icons.block, size: 20),
                  tooltip: 'Ban Selected',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _bulkDeleteUsers,
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Delete Selected',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        
        // User list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00A862)));
              }

              var users = snapshot.data?.docs ?? [];

              // Apply search filter
              if (_userSearchQuery.isNotEmpty) {
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
                }).toList();
              }

              // Apply type filter
              if (_userTypeFilter != 'all') {
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_userTypeFilter == 'Admin') {
                    return data['isAdmin'] == true;
                  }
                  return data['accountType'] == _userTypeFilter;
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found', style: TextStyle(fontFamily: 'Poppins')),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final email = data['email'] ?? '';
                  final accountType = data['accountType'] ?? 'Unknown';
                  final isAdmin = data['isAdmin'] == true;
                  final isBanned = data['banned'] == true;
                  final suspendedUntil = data['suspendedUntil'] as Timestamp?;
                  final isSuspended = suspendedUntil != null && 
                                     suspendedUntil.toDate().isAfter(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isBanned || isSuspended ? 4 : 2,
                    color: isBanned 
                        ? Colors.red.shade50 
                        : (isSuspended ? Colors.orange.shade50 : ThemeHelper.getCardColor(_themeNotifier.isDarkMode)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isBanned 
                            ? Colors.red 
                            : (isSuspended ? Colors.orange : Colors.grey.shade300),
                        width: isBanned || isSuspended ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedUserIds.contains(user.id),
                            onChanged: (isAdmin || name.toLowerCase() == 'name') ? null : (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedUserIds.add(user.id);
                                } else {
                                  _selectedUserIds.remove(user.id);
                                }
                              });
                            },
                          ),
                          CircleAvatar(
                            backgroundColor: isBanned 
                                ? Colors.red 
                                : (isAdmin ? Colors.purple : const Color(0xFF00A862)),
                            child: Icon(
                              isBanned 
                                  ? Icons.block 
                                  : (isAdmin ? Icons.admin_panel_settings : Icons.person),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$email\nType: $accountType${isAdmin ? ' • Admin' : ''}${isBanned ? ' • BANNED' : ''}${isSuspended ? ' • SUSPENDED' : ''}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                          _buildUserActionsMenu(context, user.id, name, data, isAdmin, isBanned, isSuspended),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 4: Products Management
  Widget _buildProductsTab() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products by name or farmer...',
              hintStyle: const TextStyle(fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _productSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _productSearchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _productSearchQuery = value.toLowerCase()),
          ),
        ),
        
        // Product list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00A862)));
              }

              var products = snapshot.data?.docs ?? [];

              // Apply search filter
              if (_productSearchQuery.isNotEmpty) {
                products = products.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final farmerName = (data['farmerName'] ?? '').toString().toLowerCase();
                  return name.contains(_productSearchQuery) || farmerName.contains(_productSearchQuery);
                }).toList();
              }

              if (products.isEmpty) {
                return const Center(
                  child: Text('No products found', style: TextStyle(fontFamily: 'Poppins')),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final data = product.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown Product';
                  final price = data['price'] ?? 0.0;
                  final quantity = data['quantity'] ?? 0;
                  final farmerName = data['farmerName'] ?? 'Unknown Farmer';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: ThemeHelper.getCardColor(isDarkMode),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF00A862),
                        child: Icon(Icons.inventory, color: Colors.white),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Price: ₱$price • Qty: $quantity\nFarmer: $farmerName',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF00A862)),
                            onPressed: () => _editProduct(product.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product.id, name),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 5: Orders Management
  Widget _buildOrdersTab() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Column(
      children: [
        // Filter bar
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
              FilterChip(
                label: const Text('All', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                selected: _orderStatusFilter == 'all',
                selectedColor: const Color(0xFF00A862),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(
                  color: _orderStatusFilter == 'all' ? Colors.white : Colors.black,
                ),
                onSelected: (selected) => setState(() => _orderStatusFilter = 'all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pending', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                selected: _orderStatusFilter == 'pending',
                selectedColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(
                  color: _orderStatusFilter == 'pending' ? Colors.white : Colors.black,
                ),
                onSelected: (selected) => setState(() => _orderStatusFilter = 'pending'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Confirmed', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                selected: _orderStatusFilter == 'confirmed',
                selectedColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(
                  color: _orderStatusFilter == 'confirmed' ? Colors.white : Colors.black,
                ),
                onSelected: (selected) => setState(() => _orderStatusFilter = 'confirmed'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Delivered', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                selected: _orderStatusFilter == 'delivered',
                selectedColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(
                  color: _orderStatusFilter == 'delivered' ? Colors.white : Colors.black,
                ),
                onSelected: (selected) => setState(() => _orderStatusFilter = 'delivered'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Cancelled', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                selected: _orderStatusFilter == 'cancelled',
                selectedColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(
                  color: _orderStatusFilter == 'cancelled' ? Colors.white : Colors.black,
                ),
                onSelected: (selected) => setState(() => _orderStatusFilter = 'cancelled'),
              ),
            ],
          ),
        ),
        ),
        
        // Orders list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00A862)));
              }

              var orders = snapshot.data?.docs ?? [];

              // Apply status filter
              if (_orderStatusFilter != 'all') {
                orders = orders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == _orderStatusFilter;
                }).toList();
              }

              if (orders.isEmpty) {
                return const Center(
                  child: Text('No orders found', style: TextStyle(fontFamily: 'Poppins')),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  
                  // Extract product names from items array
                  String productName = 'Unknown';
                  if (data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
                    final items = data['items'] as List;
                    final productNames = items.map((item) => item['name'] ?? 'Unknown').toList();
                    productName = productNames.join(', ');
                  }
                  
                  final buyerName = data['buyerName'] ?? 'Unknown';
                  final sellerName = data['farmerName'] ?? 'Unknown';
                  final status = data['status'] ?? 'pending';
                  final total = data['totalAmount'] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: ThemeHelper.getCardColor(isDarkMode),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getOrderStatusColor(status),
                        child: const Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text(
                        productName,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Buyer: $buyerName\nSeller: $sellerName\nStatus: $status • ₱$total',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 6: Messages Management
  Widget _buildMessagesTab() {
    final isDarkMode = false;
    
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search conversations by user name...',
              hintStyle: const TextStyle(fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _messageSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _messageSearchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _messageSearchQuery = value.toLowerCase()),
          ),
        ),
        
        // Conversations list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('conversations').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00A862)));
              }

              var conversations = snapshot.data?.docs ?? [];

              // Apply search filter
              if (_messageSearchQuery.isNotEmpty) {
                conversations = conversations.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final buyerName = (data['buyerName'] ?? '').toString().toLowerCase();
                  final farmerName = (data['farmerName'] ?? '').toString().toLowerCase();
                  final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();
                  return buyerName.contains(_messageSearchQuery) || 
                         farmerName.contains(_messageSearchQuery) ||
                         lastMessage.contains(_messageSearchQuery);
                }).toList();
              }

              if (conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No conversations yet', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final data = conversation.data() as Map<String, dynamic>;
                  final buyerName = data['buyerName'] ?? 'Unknown';
                  final farmerName = data['farmerName'] ?? 'Unknown';
                  final buyerId = data['buyerId'] ?? '';
                  final farmerId = data['farmerId'] ?? '';
                  final lastMessage = data['lastMessage'] ?? '';
                  final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
                  final productName = data['productName'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: ThemeHelper.getCardColor(isDarkMode),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF00A862),
                        child: Icon(Icons.chat, color: Colors.white),
                      ),
                      title: Text(
                        'Buyer: $buyerName ↔ Farmer: $farmerName',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${productName != null ? 'Re: $productName\n' : ''}${lastMessage.isEmpty ? 'No messages yet' : lastMessage}\n${lastMessageTime != null ? _formatDate(lastMessageTime) : 'Unknown time'}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Color(0xFF00A862)),
                            tooltip: 'View conversation',
                            onPressed: () => _viewConversationDetails(conversation.id, buyerName, farmerName, buyerId, farmerId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete conversation',
                            onPressed: () => _deleteConversation(conversation.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildUserActionsMenu(BuildContext context, String userId, String name, Map<String, dynamic> data, bool isAdmin, bool isBanned, bool isSuspended) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final isProtected = isAdmin || name.toLowerCase() == 'name';

    return IconButton(
      icon: Icon(
        Icons.more_vert,
        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
      ),
      tooltip: 'User actions',
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('User Actions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('View Details', style: TextStyle(fontFamily: 'Poppins')),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showUserDetailsDelayed(userId, data);
                      },
                    ),
                    if (!isProtected && !isBanned && !isSuspended) ...[
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: const Text('Ban User', style: TextStyle(fontFamily: 'Poppins', color: Colors.red)),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          final banResult = await showDialog<Map>(
                            context: context,
                            builder: (context) => _buildBanUserDialog(userId, name, permanent: true),
                          );
                          if (!mounted) return;
                          if (banResult != null && banResult['confirm'] == true) {
                            await _banUser(userId, name, banResult['reason'], true, null, banResult['deleteData'] ?? false);
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.timelapse, color: Colors.orange),
                        title: const Text('Suspend User', style: TextStyle(fontFamily: 'Poppins', color: Colors.orange)),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          final suspendResult = await showDialog<Map>(
                            context: context,
                            builder: (context) => _buildBanUserDialog(userId, name, permanent: false),
                          );
                          if (!mounted) return;
                          if (suspendResult != null && suspendResult['confirm'] == true) {
                            await _banUser(userId, name, suspendResult['reason'], false, suspendResult['suspendDays'], suspendResult['deleteData'] ?? false);
                          }
                        },
                      ),
                    ],
                    if (!isProtected && (isBanned || isSuspended))
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: const Text('Unban/Unsuspend', style: TextStyle(fontFamily: 'Poppins', color: Colors.green)),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          final unbanResult = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildUnbanDialog(userId, name),
                          );
                          if (!mounted) return;
                          if (unbanResult == true) {
                            await _unbanUser(userId, name);
                          }
                        },
                      ),
                    if (!isProtected)
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Delete User', style: TextStyle(fontFamily: 'Poppins', color: Colors.red)),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          final deleteResult = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildDeleteUserDialog(userId, name),
                          );
                          if (!mounted) return;
                          if (deleteResult == true) {
                            await _performFullUserDeletion(userId);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetailsDelayed(String userId, Map<String, dynamic> data) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (detailContext) => _buildUserDetailsDialog(userId, data),
      );
    });
  }

  Widget _buildUserDetailsDialog(String userId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'N/A';
    final accountType = data['accountType'] ?? 'Unknown';
    final location = data['location'] ?? 'N/A';
    final isAdmin = data['isAdmin'] == true;
    final isBanned = data['banned'] == true;
    final isSuspended = data['suspended'] == true;
    final banReason = data['banReason'] ?? '';
    final suspendedUntil = data['suspendedUntil'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final averageRating = data['averageRating'] ?? 0.0;
    final reviewCount = data['reviewCount'] ?? 0;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: isBanned 
                ? Colors.red 
                : (isAdmin ? Colors.purple : const Color(0xFF00A862)),
            child: Icon(
              isBanned 
                  ? Icons.block 
                  : (isAdmin ? Icons.admin_panel_settings : Icons.person),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: FutureBuilder<Map<String, int>>(
          future: _getUserStats(userId, accountType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final stats = snapshot.data ?? {'products': 0, 'orders': 0};
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(Icons.email, 'Email', email),
                _detailRow(Icons.person_outline, 'Account Type', accountType),
                _detailRow(Icons.location_on, 'Location', location),
                if (isAdmin)
                  _detailRow(Icons.admin_panel_settings, 'Role', 'Administrator', color: Colors.purple),
                if (isBanned)
                  _detailRow(Icons.block, 'Status', 'PERMANENTLY BANNED', color: Colors.red),
                if (isSuspended)
                  _detailRow(Icons.block, 'Suspended Until', suspendedUntil != null ? _formatDate(suspendedUntil.toDate()) : 'Unknown', color: Colors.orange),
                if (banReason.isNotEmpty)
                  _detailRow(Icons.info_outline, 'Ban/Suspend Reason', banReason, color: Colors.red),
                if (createdAt != null)
                  _detailRow(Icons.calendar_today, 'Account Created', _formatDate(createdAt.toDate())),
                const Divider(height: 24),
                _detailRow(Icons.star, 'Average Rating', '${averageRating.toStringAsFixed(1)} ⭐ ($reviewCount reviews)'),
                if (accountType == 'Farmer')
                  _detailRow(Icons.inventory, 'Products', '${stats['products']}'),
                _detailRow(Icons.shopping_bag, 'Orders', '${stats['orders']}'),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(fontFamily: 'Poppins')),
        ),
      ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getUserStats(String userId, String accountType) async {
    int productCount = 0;
    if (accountType == 'Farmer') {
      final products = await FirebaseFirestore.instance
          .collection('products')
          .where('farmerId', isEqualTo: userId)
          .get();
      productCount = products.docs.length;
    }
    
    final buyerOrders = await FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .get();
    final sellerOrders = await FirebaseFirestore.instance
        .collection('orders')
        .where('farmerId', isEqualTo: userId)
        .get();
    final totalOrders = buyerOrders.docs.length + sellerOrders.docs.length;

    return {'products': productCount, 'orders': totalOrders};
  }

  Widget _buildDeleteUserDialog(String userId, String userName) {
    return AlertDialog(
      title: const Text('Delete User', style: TextStyle(fontFamily: 'Poppins')),
      content: Text(
        'Are you sure you want to delete "$userName"? This will remove all their data.',
        style: const TextStyle(fontFamily: 'Poppins'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildBanUserDialog(String userId, String userName, {required bool permanent}) {
    final reasonController = TextEditingController();
    int? suspendDays;
    bool deleteData = false;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(
            permanent ? 'Ban User Permanently' : 'Suspend User Temporarily',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permanent 
                      ? 'Permanently ban "$userName"? They will not be able to log in.'
                      : 'Temporarily suspend "$userName"?',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (!permanent) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Suspend Duration',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 day')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 14, child: Text('14 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                    ],
                    onChanged: (value) => suspendDays = value,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text(
                    'Delete all user data',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  subtitle: const Text(
                    'This will permanently delete:\n• Messages & conversations\n• Products & orders\n• Notifications\n• All user content',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  value: deleteData,
                  onChanged: (value) {
                    setDialogState(() => deleteData = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                reasonController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                if (!permanent && suspendDays == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select suspension duration')),
                  );
                  return;
                }
                
                Navigator.pop(context, {
                  'confirm': true,
                  'reason': reasonController.text,
                  'suspendDays': suspendDays,
                  'deleteData': deleteData,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(permanent ? 'Ban' : 'Suspend', style: const TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnbanDialog(String userId, String userName) {
    return AlertDialog(
      title: const Text('Unban/Unsuspend User', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
      content: Text(
        'Remove ban/suspension from "$userName"?',
        style: const TextStyle(fontFamily: 'Poppins'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Unban'),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to delete user data (used by both ban and delete functions)
  Future<void> _deleteUserData(String userId) async {
    try {
      // Delete messages sent by user
      final messagesQuery = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      
      for (var doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete messages received by user
      final receivedMessagesQuery = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      
      for (var doc in receivedMessagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete conversations where user is a participant
      final conversationsQuery = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();
      
      for (var doc in conversationsQuery.docs) {
        // Delete all messages in conversation
        final messagesInConv = await doc.reference.collection('messages').get();
        for (var msg in messagesInConv.docs) {
          await msg.reference.delete();
        }
        // Delete conversation itself
        await doc.reference.delete();
      }

      // Delete user notifications
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in notificationsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user products
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('farmerId', isEqualTo: userId)
          .get();
      
      for (var doc in productsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete orders where user is buyer
      final ordersAsBuyerQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .get();
      
      for (var doc in ordersAsBuyerQuery.docs) {
        await doc.reference.delete();
      }

      // Delete orders where user is seller
      final ordersAsSellerQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      for (var doc in ordersAsSellerQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user feedback
      final feedbackQuery = await FirebaseFirestore.instance
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in feedbackQuery.docs) {
        await doc.reference.delete();
      }

      // Delete account action requests for user
      final requestsQuery = await FirebaseFirestore.instance
          .collection('accountActionRequests')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in requestsQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ All user data deleted for: $userId');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  Future<void> _performFullUserDeletion(String userId) async {
    setState(() => _isProcessing = true);

    try {
      // Call Cloud Function to delete user from Auth + Firestore
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
      final result = await callable.call({'userId': userId});

      if (!mounted) return;
      
      if (result.data['success'] == true) {
        _showSuccess('User and all associated data deleted successfully');
      } else {
        _showError('Failed to delete user: ${result.data['message']}');
      }
    } catch (e) {
      print('Error calling deleteUserAccount Cloud Function: $e');
      
      // Fallback to local deletion (Firestore only - Auth deletion requires Cloud Function)
      try {
        // Delete all user data first
        await _deleteUserData(userId);

        // Delete user document from Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        if (!mounted) return;
        _showSuccess('User data deleted from Firestore. Note: User may still exist in Auth - deploy Cloud Function for complete deletion.');
      } catch (fallbackError) {
        if (!mounted) return;
        _showError('Error deleting user: $fallbackError');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Delete "$productName"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).delete();
        _showSuccess('Product deleted');
      } catch (e) {
        _showError('Error: $e');
      }
    }
  }

  Future<void> _editProduct(String productId, Map<String, dynamic> currentData) async {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final descController = TextEditingController(text: currentData['description'] ?? '');
    final priceController = TextEditingController(text: (currentData['price'] ?? 0.0).toString());
    final quantityController = TextEditingController(text: (currentData['quantity'] ?? 0).toString());
    final categoryController = TextEditingController(text: currentData['category'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A862)),
            child: const Text('Save', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final price = double.tryParse(priceController.text) ?? 0.0;
        final quantity = int.tryParse(quantityController.text) ?? 0;

        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'name': nameController.text.trim(),
          'description': descController.text.trim(),
          'price': price,
          'quantity': quantity,
          'category': categoryController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        _showSuccess('Product updated successfully');
      } catch (e) {
        _showError('Error updating product: $e');
      }
    }

    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    quantityController.dispose();
    categoryController.dispose();
  }

  Future<void> _viewConversationDetails(String conversationId, String buyerName, String farmerName, String buyerId, String farmerId) async {
    final isDarkMode = false;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          decoration: BoxDecoration(
            color: ThemeHelper.getBackgroundColor(isDarkMode),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF00A862),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conversation Details',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Buyer: $buyerName ↔ Farmer: $farmerName',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Messages list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A862)));
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages in this conversation',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final data = message.data() as Map<String, dynamic>;
                        final text = data['text'] ?? '';
                        final senderId = data['senderId'] ?? '';
                        final senderName = data['senderName'] ?? 'Unknown';
                        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                        final isBuyer = senderId == buyerId;

                        return Align(
                          alignment: isBuyer ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              crossAxisAlignment: isBuyer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      senderName,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isBuyer ? '(Buyer)' : '(Farmer)',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isBuyer ? Colors.blue[50] : const Color(0xFF00A862),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        text,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: isBuyer ? Colors.black87 : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timestamp != null ? _formatDate(timestamp) : '',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          color: isBuyer ? Colors.grey[600] : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation?', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'This will permanently delete this entire conversation and all its messages.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete all messages in the conversation
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Delete the conversation document
        batch.delete(FirebaseFirestore.instance.collection('conversations').doc(conversationId));

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted successfully', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting conversation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting conversation: $e', style: const TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resolveFeedback(String feedbackId, String status) async {
    final statusLabel = status == 'resolved' ? 'Resolved' : 'Dismissed';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark as $statusLabel',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to mark this feedback as $statusLabel?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'resolved' ? Colors.green : Colors.grey,
            ),
            child: Text('Confirm', style: const TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Update feedback status
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({
        'status': status,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      _showSuccess('Feedback marked as $statusLabel');
    } catch (e) {
      if (!mounted) return;
      _showError('Error updating feedback: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Ban/Suspend System Methods
  Future<void> _banUser(String userId, String userName, String reason, bool permanent, int? days, bool deleteData) async {
    setState(() => _isProcessing = true);

    try {
      // If deleteData is true, delete all user data first
      if (deleteData) {
        await _deleteUserData(userId);
      }

      final banData = <String, dynamic>{
        'banned': permanent,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      };

      if (!permanent && days != null) {
        banData['suspendedUntil'] = Timestamp.fromDate(
          DateTime.now().add(Duration(days: days)),
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update(banData);

      // Log the ban/suspension
      await FirebaseFirestore.instance.collection('bans').add({
        'userId': userId,
        'userName': userName,
        'reason': reason,
        'permanent': permanent,
        'duration': days,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      _showSuccess('User ${permanent ? 'banned' : 'suspended'} successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _unbanUser(String userId, String userName) async {
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'banned': false,
        'suspended': false,
        'suspendedUntil': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });

      if (!mounted) return;
      _showSuccess('User unbanned successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Bulk Actions Methods
  void _toggleSelectAllUsers() {
    setState(() {
      if (_selectedUserIds.isEmpty) {
        // Select all visible users
        FirebaseFirestore.instance.collection('users').get().then((snapshot) {
          setState(() {
            _selectedUserIds = snapshot.docs.map((doc) => doc.id).toSet();
          });
        });
      } else {
        // Deselect all
        _selectedUserIds.clear();
      }
    });
  }

  Future<void> _bulkBanUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban Selected Users', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Permanently ban ${_selectedUserIds.length} users?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ban All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      
      for (final userId in _selectedUserIds) {
        try {
          await _banUser(userId, 'User', 'Bulk ban by admin', true, null, false);
        } catch (e) {
          print('Error banning user $userId: $e');
        }
      }
      
      setState(() {
        _selectedUserIds.clear();
        _isProcessing = false;
      });
      
      _showSuccess('Bulk ban completed');
    }
  }

  Future<void> _bulkDeleteUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Users', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Delete ${_selectedUserIds.length} users and all their data? This cannot be undone!',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      
      
      for (final userId in _selectedUserIds) {
        try {
          await _performFullUserDeletion(userId);
        } catch (e) {
          print('Error deleting user $userId: $e');
        }
      }
      
      setState(() {
        _selectedUserIds.clear();
        _isProcessing = false;
      });
      
      _showSuccess('Bulk deletion completed');
    }
  }


}





