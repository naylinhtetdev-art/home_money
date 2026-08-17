import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_money/services/notification_service.dart';
import 'package:home_money/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService.instance;

  List<NotificationModel> _notifications = [];

  StreamSubscription? _subscription;

  bool _loading = false;

  List<NotificationModel> get notifications => _notifications;

  bool get loading => _loading;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void start(String uid) {
    _subscription?.cancel();

    _loading = true;
    notifyListeners();

    _subscription = _service
        .watchNotifications(uid)
        .listen(
          (snapshot) {
            _notifications = snapshot.docs
                .map(
                  (doc) => NotificationModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList();

            _loading = false;

            notifyListeners();
          },
          onError: (error) {
            debugPrint('Notification stream error: $error');

            _loading = false;
            notifyListeners();
          },
        );
  }

  /// Stop watching notifications and clear state.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _loading = false;
    notifyListeners();
  }

  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await _service.markAsRead(uid: uid, notificationId: notificationId);
  }

  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    await _service.deleteNotification(uid: uid, notificationId: notificationId);
  }

  Future<void> markAllAsRead(String uid) async {
    await _service.markAllAsRead(uid);

    // Stream က update ပြန်လာမှာဖြစ်လို့
    // manually list update လုပ်စရာမလိုပါဘူး။
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
