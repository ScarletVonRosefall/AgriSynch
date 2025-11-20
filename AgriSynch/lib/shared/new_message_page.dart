import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'message_permission.dart';
import 'theme_helper.dart';

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All'; // All, Farmer, Buyer
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getUsersStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Get all users - we'll filter by role in memory to avoid index requirement
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId) // Exclude current user
          .map((doc) {
            final data = doc.data();
            final rawRole = data['accountType'] ?? data['userType'] ?? data['role'] ?? 'user';
            
            // Clean up invalid/placeholder data
            String finalRole = rawRole.toString();
            if (finalRole.toLowerCase().contains('selected') || 
                finalRole.toLowerCase().contains('account') ||
                finalRole.toLowerCase().contains('type') ||
                finalRole.isEmpty ||
                finalRole == 'null') {
              finalRole = 'user'; // Default for invalid data
            }
            
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'email': data['email'] ?? '',
              'role': finalRole,
              'location': data['location'] ?? '',
            };
          })
          .where((user) {
            // Filter out placeholder/test users
            final name = user['name'].toString().toLowerCase();
            final email = user['email'].toString().toLowerCase();
            
            // Skip users with placeholder data
            if (name == 'unknown' || name == 'name' || name.isEmpty ||
                email == 'email' || email.isEmpty || !email.contains('@')) {
              return false;
            }
            
            // Filter by role in memory (client-side)
            if (_selectedRole == 'All') return true;
            final userRole = user['role'].toString().toLowerCase();
            final selectedRole = _selectedRole.toLowerCase();
            return userRole == selectedRole;
          })
          .toList();
    });
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((user) {
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final location = user['location'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || 
             email.contains(query) || 
             location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Fixed Top Green Header ---
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/buyer-home');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'New Message',
                      style: ThemeHelper.getHeaderTextStyle(
                        isDark: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  height: 42,
                  decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: ThemeHelper.getIconColor(isDarkMode)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or location...',
                            border: InputBorder.none,
                            hintStyle: ThemeHelper.getHintTextStyle(isDark: isDarkMode),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: ThemeHelper.getIconColor(isDarkMode)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter chips
                Row(
                  children: [
                    Text(
                      'Show: ', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedRole == 'All',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRole = 'All');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Farmers'),
                      selected: _selectedRole == 'Farmer',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRole = 'Farmer');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Buyers'),
                      selected: _selectedRole == 'Buyer',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRole = 'Buyer');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Scrollable User List ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final allUsers = snapshot.data ?? [];
          final filteredUsers = _filterUsers(allUsers);

          if (filteredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    allUsers.isEmpty ? 'No users found' : 'No matching users',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final userRole = user['role'].toString();
              final userRoleLower = userRole.toLowerCase();
              final isFarmer = userRoleLower == 'farmer';
              final isBuyer = userRoleLower == 'buyer';
              
              // Determine display role and colors
              String displayRole;
              Color backgroundColor;
              Color textColor;
              
              if (isFarmer) {
                displayRole = 'FARMER';
                backgroundColor = Colors.green[100]!;
                textColor = Colors.green[800]!;
              } else if (isBuyer) {
                displayRole = 'BUYER';
                backgroundColor = Colors.blue[100]!;
                textColor = Colors.blue[800]!;
              } else {
                // For any remaining edge cases, show as USER
                displayRole = 'USER';
                backgroundColor = Colors.grey[200]!;
                textColor = Colors.grey[800]!;
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFarmer ? Colors.green : (isBuyer ? Colors.blue : Colors.grey),
                  child: Text(
                    user['name'].toString().isNotEmpty
                        ? user['name'].toString()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayRole,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user['location'].toString().isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on, 
                            size: 14, 
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    if (user['email'].toString().isNotEmpty)
                      Text(
                        user['email'],
                        style: TextStyle(
                          fontSize: 11, 
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Capture stable UI objects before async gaps
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  // Check permission before navigating to chat
                  final allowed = await canMessageUser(user['id']);
                  // Ensure widget still mounted immediately after awaiting
                  if (!mounted) return;
                  if (!allowed) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('You cannot message admin accounts.')),
                    );
                    return;
                  }
                  // Navigate to chat screen with this user
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: user['id'],
                        otherUserName: user['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}
