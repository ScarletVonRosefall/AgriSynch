import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import 'dart:math';
import 'rate_limit_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static String generateMessageId(String senderId, String message) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(100000);
    final messageHash = message.hashCode.abs();
    return '${senderId}_${timestamp}_${messageHash}_${random}';
  }

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
        print('❌ ChatService: No authenticated user');
        return false;
      }

      // Check rate limit
      final canSend = await RateLimitService.checkRateLimit(
        'message_send',
        userId: currentUser.uid,
      );
      if (!canSend) {
        final errorMessage = RateLimitService.getRateLimitMessage('message_send');
        print('🚫 ChatService: $errorMessage');
        throw Exception(errorMessage);
      }

      final senderId = currentUser.uid;
      final senderName = currentUser.displayName ?? 'User';
      final conversationId = generateConversationId(senderId, receiverId);
      
      final messageId = generateMessageId(senderId, message);
      
      print('🔧 ChatService: Sending message');
      print('   📋 MessageID: $messageId');
      print('   💬 Content: "$message"');
      print('   👤 From: $senderId -> $receiverId');

      final existingMessage = await _firestore
          .collection('messages')
          .doc(messageId)
          .get();
          
      if (existingMessage.exists) {
        print('🚫 ChatService: Message with this ID already exists');
        return false;
      }

      print('✅ ChatService: Message ID is unique, proceeding to send');

      final chatMessage = ChatMessage(
        id: messageId,
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

      print('💾 ChatService: Saving to Firestore...');
      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(chatMessage.toFirestore());
      print('✅ ChatService: Message saved to Firestore');

      print('🔄 ChatService: Updating conversation...');
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversationDoc = await conversationRef.get();

      if (conversationDoc.exists) {
        await conversationRef.update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': FieldValue.increment(1),
        });
      } else {
        // TODO: Determine actual buyer/farmer roles from user data
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

      // TODO: Add push notification when NotificationService supports it
      
      print('🎉 ChatService: Message send completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('❌ ChatService: Error sending message: $e');
      print('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  static Stream<List<ChatMessage>> getMessagesStream(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final conversationId = generateConversationId(currentUser.uid, otherUserId);

    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
      
      // Remove duplicates - same sender, content, and timestamp within 2 seconds
      final deduplicatedMessages = <ChatMessage>[];
      for (final message in messages) {
        final isDuplicate = deduplicatedMessages.any((existing) => 
          existing.senderId == message.senderId &&
          existing.message == message.message &&
          existing.timestamp.difference(message.timestamp).abs().inSeconds < 2
        );
        
        if (!isDuplicate) {
          deduplicatedMessages.add(message);
        } else {
          print('🚫 Stream: Filtering out duplicate message: "${message.message}"');
        }
      }
      
      deduplicatedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return deduplicatedMessages;
    });
  }

  static Stream<List<Conversation>> getConversationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final userId = currentUser.uid;

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();
      
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      return conversations;
    });
  }

  static Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final conversationId = generateConversationId(currentUser.uid, otherUserId);

      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        if (doc.data()['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

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

  static Future<bool> deleteConversation(String conversationId) async {
    try {
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
      print('✅ Conversation deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }

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
