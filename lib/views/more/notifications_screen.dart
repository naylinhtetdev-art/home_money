import 'package:flutter/material.dart';
import 'package:home_money/providers/auth_provider.dart';
import 'package:home_money/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _startedFor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<NotificationProvider>();

    if (auth.user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final uid = auth.user!.uid;

    // Start provider stream once per user
    if (_startedFor != uid) {
      _startedFor = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().start(uid);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                provider.markAllAsRead(uid);
              },
              child: const Text('Read all'),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];

                return _NotificationCard(
                  id: notification.id,
                  title: notification.title,
                  body: notification.message,
                  isRead: notification.isRead,
                  createdAt: notification.createdAt,
                  onTap: () async {
                    if (!notification.isRead) {
                      await provider.markAsRead(
                        uid: uid,
                        notificationId: notification.id,
                      );
                    }
                  },
                  onDelete: () {
                    provider.deleteNotification(
                      uid: uid,
                      notificationId: notification.id,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 0,
        color: isRead
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
          onTap: onTap,

          leading: CircleAvatar(
            child: Icon(
              isRead ? Icons.notifications_none : Icons.notifications,
            ),
          ),

          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(body),
              const SizedBox(height: 6),
              Text(
                _formatDate(createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          trailing: !isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
