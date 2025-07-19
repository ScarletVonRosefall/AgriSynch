import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_helper.dart';
import 'theme_helper.dart';

class AgriNotificationPage extends StatefulWidget {
  const AgriNotificationPage({super.key});

  @override
  State<AgriNotificationPage> createState() => _AgriNotificationPageState();
}

class _AgriNotificationPageState extends State<AgriNotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isDarkMode = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
    loadTheme();
  }

  Future<void> loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  Future<void> loadNotifications() async {
    setState(() => isLoading = true);
    notifications = await NotificationHelper.getNotifications();
    setState(() => isLoading = false);
  }

  Future<void> markAsRead(String notificationId) async {
    await NotificationHelper.markAsRead(notificationId);
    await loadNotifications();
  }

  Future<void> deleteNotification(String notificationId) async {
    await NotificationHelper.deleteNotification(notificationId);
    await loadNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  Future<void> markAllAsRead() async {
    await NotificationHelper.markAllAsRead();
    await loadNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  Future<void> clearAllNotifications() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotificationHelper.clearAllNotifications();
              await loadNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                          Text(
                            '${notifications.length} total notifications',
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ],
                      ),
                    ),
                    if (notifications.isNotEmpty) ...[
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          switch (value) {
                            case 'mark_all_read':
                              markAllAsRead();
                              break;
                            case 'clear_all':
                              clearAllNotifications();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'mark_all_read',
                            child: Row(
                              children: [
                                Icon(Icons.done_all),
                                SizedBox(width: 8),
                                Text('Mark all as read'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear_all',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Clear all', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: isDarkMode ? Colors.white60 : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'re all caught up!',
                              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                                color: isDarkMode ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final timestamp = DateTime.parse(notification['timestamp']);
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'system';
    final icon = NotificationHelper.getNotificationIcon(type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A))
            : (isRead ? Colors.white : const Color(0xFFF0F8FF)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead 
              ? (isDarkMode ? Colors.grey[700]! : Colors.grey[200]!)
              : ThemeHelper.getHeaderColor(isDarkMode).withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'] ?? 'Notification',
                style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ThemeHelper.getHeaderColor(isDarkMode),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(timestamp),
              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                markAsRead(notification['id']);
                break;
              case 'delete':
                deleteNotification(notification['id']);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationHelper.taskReminder:
        return Colors.blue;
      case NotificationHelper.orderUpdate:
        return Colors.orange;
      case NotificationHelper.taskDeadline:
        return Colors.red;
      case NotificationHelper.systemNotification:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
