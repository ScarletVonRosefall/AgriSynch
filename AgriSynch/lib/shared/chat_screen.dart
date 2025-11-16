import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/review_service.dart';
import 'theme_helper.dart';
import 'report_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? orderId;
  final String? productId;
  final String? productName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.orderId,
    this.productId,
    this.productName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    // Mark messages as read when opening chat
    ChatService.markMessagesAsRead(widget.otherUserId);
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    // Clear the text field immediately to prevent double-send
    _messageController.clear();

    final success = await ChatService.sendMessage(
      receiverId: widget.otherUserId,
      receiverName: widget.otherUserName,
      message: message,
      orderId: widget.orderId,
      productId: widget.productId,
      productName: widget.productName,
    );

    setState(() => _isSending = false);

    if (success) {
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      // Restore message if send failed
      _messageController.text = message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe 
              ? (isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50))
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe 
                        ? Colors.white.withOpacity(0.8)
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead 
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Today';
    } else if (difference.inDays == 1) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            style: ThemeHelper.getHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                          if (widget.productName != null)
                            Text(
                              'About: ${widget.productName}',
                              style: ThemeHelper.getSubHeaderTextStyle(
                                isDark: isDarkMode,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Info Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () async {
                          // Fetch user information
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.otherUserId)
                              .get();
                          
                          final userData = userDoc.data();
                          final userType = userData?['accountType'] ?? userData?['userType'] ?? userData?['role'] ?? 'User';
                          final email = userData?['email'] ?? 'N/A';
                          final phone = userData?['phone'] ?? 'N/A';
                          final bio = userData?['bio'] ?? '';
                          final location = userData?['location'] ?? 'N/A';
                          final barangay = userData?['barangay'] ?? '';
                          final municipality = userData?['municipality'] ?? '';
                          final province = userData?['province'] ?? '';
                          
                          String fullLocation = location;
                          if (barangay.isNotEmpty || municipality.isNotEmpty || province.isNotEmpty) {
                            List<String> locationParts = [];
                            if (barangay.isNotEmpty) locationParts.add(barangay);
                            if (municipality.isNotEmpty) locationParts.add(municipality);
                            if (province.isNotEmpty) locationParts.add(province);
                            if (locationParts.isNotEmpty) {
                              fullLocation = locationParts.join(', ');
                            }
                          }
                          
                          // Get rating stats if other user is a farmer
                          Map<String, dynamic>? ratingStats;
                          if (userType.toLowerCase() == 'farmer') {
                            ratingStats = await ReviewService.getFarmerRatingStats(widget.otherUserId);
                          }
                          
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('User Info'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(Icons.person, 'Name', widget.otherUserName),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(Icons.badge, 'Type', userType),
                                      if (ratingStats != null) ...[
                                        const SizedBox(height: 12),
                                        _buildRatingRow(
                                          ratingStats['averageRating'] ?? 0.0,
                                          ratingStats['reviewCount'] ?? 0,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      _buildInfoRow(Icons.email, 'Email', email),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(Icons.phone, 'Phone', phone),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(Icons.location_on, 'Location', fullLocation),
                                      if (bio.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        _buildInfoRow(Icons.description, 'Bio', bio),
                                      ],
                                      if (widget.productName != null) ...[
                                        const SizedBox(height: 12),
                                        _buildInfoRow(Icons.shopping_bag, 'Product', widget.productName!),
                                      ],
                                      if (widget.orderId != null) ...[
                                        const SizedBox(height: 12),
                                        _buildInfoRow(Icons.receipt, 'Order ID', widget.orderId!),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => ReportDialog(
                                          reportType: 'user',
                                          reportedItemId: widget.otherUserId,
                                          reportedItemName: widget.otherUserName,
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.flag, size: 18),
                                        SizedBox(width: 4),
                                        Text('Report'),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Messages List ---
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getMessagesStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    // Show date divider for first message of each day
                    bool showDateDivider = false;
                    if (index < messages.length - 1) {
                      final nextMessage = messages[index + 1];
                      if (message.timestamp.day != nextMessage.timestamp.day ||
                          message.timestamp.month !=
                              nextMessage.timestamp.month ||
                          message.timestamp.year != nextMessage.timestamp.year) {
                        showDateDivider = true;
                      }
                    } else {
                      showDateDivider = true; // Always show for oldest message
                    }

                    return Column(
                      children: [
                        _buildMessageBubble(message, isMe),
                        if (showDateDivider)
                          _buildDateDivider(message.timestamp),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSending) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(double averageRating, int reviewCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.star, size: 20, color: Colors.amber[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    if (index < averageRating.floor()) {
                      return Icon(Icons.star, size: 16, color: Colors.amber[700]);
                    } else if (index < averageRating && averageRating % 1 >= 0.5) {
                      return Icon(Icons.star_half, size: 16, color: Colors.amber[700]);
                    } else {
                      return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
                    }
                  }),
                  const SizedBox(width: 6),
                  Text(
                    '${averageRating.toStringAsFixed(1)} ($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
