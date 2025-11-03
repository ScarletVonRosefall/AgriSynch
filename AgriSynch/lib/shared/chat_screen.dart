import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    ChatService.markMessagesAsRead(widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

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
      _messageController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.grey,
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (widget.productName != null)
              Text(
                'About: ${widget.productName}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Conversation Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('With: ${widget.otherUserName}'),
                      if (widget.productName != null)
                        Text('Product: ${widget.productName}'),
                      if (widget.orderId != null)
                        Text('Order ID: ${widget.orderId}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
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

                // Group messages by date
                final groupedMessages = <String, List<ChatMessage>>{};
                for (var message in messages) {
                  final dateKey =
                      '${message.timestamp.year}-${message.timestamp.month}-${message.timestamp.day}';
                  groupedMessages.putIfAbsent(dateKey, () => []);
                  groupedMessages[dateKey]!.add(message);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length +
                      groupedMessages.keys.length, // Add date dividers
                  itemBuilder: (context, index) {
                    // This is simplified - you might want better date divider logic
                    final message = messages[index % messages.length];
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
                    onSubmitted: _isSending ? null : (_) => _sendMessage(),
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
}
