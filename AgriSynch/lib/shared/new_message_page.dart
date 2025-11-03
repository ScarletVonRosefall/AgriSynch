import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All'; // All, Farmer, Buyer

  @override
  void dispose() {
    _searchController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              
              // Role filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Text('Show: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    allUsers.isEmpty ? 'No users found' : 'No matching users',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
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
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            user['location'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    if (user['email'].toString().isNotEmpty)
                      Text(
                        user['email'],
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
    );
  }
}
