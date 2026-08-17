class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
  final String id, title, message;
  final DateTime createdAt;
  final bool isRead;
  factory NotificationModel.fromMap(String id, Map<String, dynamic> m) =>
      NotificationModel(
        id: id,
        title: m['title'] ?? '',
        message: m['message'] ?? '',
        createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        isRead: m['isRead'] ?? false,
      );
}
