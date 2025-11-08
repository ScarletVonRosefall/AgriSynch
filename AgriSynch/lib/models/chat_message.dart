import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? orderId; // Optional: link to order

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.orderId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'orderId': orderId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? orderId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      orderId: orderId ?? this.orderId,
    );
  }
}

class Conversation {
  final String id;
  final String buyerId;
  final String buyerName;
  final String farmerId;
  final String farmerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? productId;
  final String? productName;
  final String? orderId;
  final List<String> participants; // For Firestore queries

  Conversation({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.farmerId,
    required this.farmerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.productId,
    this.productName,
    this.orderId,
    List<String>? participants,
  }) : participants = participants ?? [buyerId, farmerId];

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      productId: data['productId'],
      productName: data['productName'],
      orderId: data['orderId'],
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'productId': productId,
      'productName': productName,
      'orderId': orderId,
      'participants': participants,
    };
  }
}
