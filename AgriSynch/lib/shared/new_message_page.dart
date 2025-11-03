import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
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
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'email': data['email'] ?? '',
              'role': data['role'] ?? 'user',
              'location': data['location'] ?? '',
            };
          })
          .where((user) {
            // Filter by role in memory (client-side)
            if (_selectedRole == 'All') return true;
            return user['role'].toString().toLowerCase() == _selectedRole.toLowerCase();
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
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
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
              final isFarmer = user['role'].toString().toLowerCase() == 'farmer';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFarmer ? Colors.green : Colors.blue,
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
                        color: isFarmer ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['role'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFarmer ? Colors.green[800] : Colors.blue[800],
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
                onTap: () {
                  // Navigate to chat screen with this user
                  Navigator.pushReplacement(
                    context,
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
