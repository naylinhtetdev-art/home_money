import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_money/views/finance/transaction_list_screen.dart';

import '../firebase_options.dart';

/// Handle FCM messages when the app is running in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background notification received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Used when notification tap needs navigation.
  GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize FCM + local notification.
  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    this.navigatorKey = navigatorKey;

    await _requestPermission();

    await _initializeLocalNotifications();

    await _configureForegroundNotifications();

    _configureNotificationTapHandlers();

    debugPrint('NotificationService initialized');
  }

  /// Request notification permission.
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );
  }

  /// Initialize local notification plugin.
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'home_money_channel',
        'Home Money Notifications',
        description: 'Notifications for Home Money app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configure foreground FCM message.
  Future<void> _configureForegroundNotifications() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground notification received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Persist notification to Firestore for the current user (foreground only).
      try {
        await _persistNotificationToFirestore(message);
      } catch (e) {
        debugPrint('Error persisting notification: $e');
      }

      await _showLocalNotification(message);
    });
  }

  /// Persist a received FCM message to Firestore under current user's notifications.
  Future<void> _persistNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final title = message.notification?.title ?? message.data['title'] ?? '';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': title,
            'message': body,
            'data': message.data,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('Persist notification error: $e');
    }
  }

  /// Show notification while app is open.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'home_money_channel',
      'Home Money Notifications',
      channelDescription: 'Notifications for Home Money app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap.
  void _configureNotificationTapHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened from background');
      _handleNotificationTap(message);
    });
  }

  /// Handle notification tap from local notification.
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped');

    debugPrint('Payload: ${response.payload}');
  }

  /// Handle notification data and navigate.
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    debugPrint('Notification data: $data');

    final type = data['type'];

    if (type == 'transaction') {
      navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (_) => const TransactionListScreen()),
      );
    }
  }

  /// Handle notification when app was completely terminated.
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message == null) {
      return;
    }

    debugPrint('App opened from terminated state');

    debugPrint('Data: ${message.data}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(message);
    });
  }

  /// Get FCM token and save it to Firestore.
  Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();

      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      debugPrint('FCM Token: $token');

      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      debugPrint('FCM token saved to Firestore');

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed: $newToken');

        await _firestore.collection('users').doc(uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token on logout.
  Future<void> removeToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));

      debugPrint('FCM token removed');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Watch user's notifications in Firestore.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark a notification as read.
  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .set({'isRead': true}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String uid) async {
    try {
      final batch = _firestore.batch();

      final snapshots = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
