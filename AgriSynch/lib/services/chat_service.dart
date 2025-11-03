import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate conversation ID from two user IDs (consistent ordering)
  static String generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Send a message
  static Future<bool> sendMessage({
    required String receiverId,
    required String receiverName,
    required String message,
    String? orderId,
    String? productId,
    String? productName,
    String? imageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user');
        return false;
      }

      final senderId = currentUser.uid;
      final senderName = currentUser.displayName ?? 'User';

      // Generate conversation ID
      final conversationId = generateConversationId(senderId, receiverId);

      // Create message
      final chatMessage = ChatMessage(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
        orderId: orderId,
      );

      // Add message to messages collection
      await _firestore
          .collection('messages')
          .add(chatMessage.toFirestore());

      // Update or create conversation
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversationDoc = await conversationRef.get();

      if (conversationDoc.exists) {
        // Update existing conversation
        await conversationRef.update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': FieldValue.increment(1),
        });
      } else {
        // Create new conversation
        // Note: You should determine actual buyer/farmer roles from user data
        // For now, using a simple approach
        final conversation = Conversation(
          id: conversationId,
          buyerId: senderId,
          buyerName: senderName,
          farmerId: receiverId,
          farmerName: receiverName,
          lastMessage: message,
          lastMessageTime: DateTime.now(),
          unreadCount: 1,
          productId: productId,
          productName: productName,
          orderId: orderId,
        );

        await conversationRef.set(conversation.toFirestore());
      }

      // TODO: Add push notification when NotificationService is updated
      // await NotificationService().sendMessageNotification(...);

      print('✅ Message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  /// Get messages stream for a conversation
  static Stream<List<ChatMessage>> getMessagesStream(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final conversationId = generateConversationId(currentUser.uid, otherUserId);

    // Simplified query - sort in memory to avoid composite index
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
      
      // Sort by timestamp descending (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return messages;
    });
  }

  /// Get all conversations for current user
  static Stream<List<Conversation>> getConversationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final userId = currentUser.uid;

    // Simplified query without orderBy to avoid index requirement
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Sort in memory instead of in Firestore
      final conversations = snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();
      
      // Sort by lastMessageTime descending (newest first)
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      return conversations;
    });
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final conversationId = generateConversationId(currentUser.uid, otherUserId);

      // Get unread messages - simplified query to avoid index
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      // Mark as read - filter for isRead == false in memory
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        if (doc.data()['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();

      // Reset unread count in conversation
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get unread message count
  static Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete a conversation
  static Future<bool> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in conversation
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
      print('✅ Conversation deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }

  /// Search conversations
  static Future<List<Conversation>> searchConversations(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      final conversations = snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .where((conv) =>
              conv.buyerName.toLowerCase().contains(query.toLowerCase()) ||
              conv.farmerName.toLowerCase().contains(query.toLowerCase()) ||
              conv.lastMessage.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return conversations;
    } catch (e) {
      print('❌ Error searching conversations: $e');
      return [];
    }
  }
}
