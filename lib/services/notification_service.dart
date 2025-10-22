// lib/services/notification_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 🚀 Your FCM server key (keep private)
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

  /// -------------------- INIT --------------------
  Future<void> init() async {
    await Firebase.initializeApp();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Save token and listen to role-based events
    await _saveDeviceToken();
    _listenToRoleEvents();

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  /// -------------------- STATIC METHODS FOR LOGIN --------------------
  static Future<void> saveUserToken() async {
    await NotificationService()._saveDeviceToken();
  }

  static void setupFCMListeners(BuildContext context) {
    NotificationService()._listenToRoleEvents();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService()._showLocalNotification(message);
    });
  }

  /// -------------------- STATIC METHODS FOR DASHBOARDS --------------------
  static Future<void> initialize() async {
    await NotificationService().init();
  }

  static void setupFCM() {
    NotificationService()._listenToRoleEvents();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService()._showLocalNotification(message);
    });
  }

  /// -------------------- BACKGROUND HANDLER --------------------
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    print('📩 Background message received: ${message.messageId}');
  }

  /// -------------------- LOCAL NOTIFICATIONS --------------------
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.notification != null) {
      final notification = message.notification!;
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medibridge_channel',
            'MediBridge Notifications',
            channelDescription: 'Channel for MediBridge notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  /// -------------------- SAVE DEVICE TOKEN --------------------
  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _dbRef.child('users/${user.uid}/fcmToken').set(token);
        print('✅ Saved FCM token for user: ${user.uid}');
      }
    }
  }

  /// -------------------- SUBSCRIBE/UNSUBSCRIBE --------------------
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// -------------------- SEND PUSH NOTIFICATION --------------------
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final postUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final payload = {
        "to": fcmToken,
        "notification": {"title": title, "body": body, "sound": "default"},
        "data": data ?? {},
      };

      final response = await http.post(
        postUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("✅ Push notification sent successfully!");
      } else {
        print("❌ Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error sending notification: $e");
    }
  }

  /// -------------------- ROLE-BASED LISTENERS --------------------
  void _listenToRoleEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _dbRef.child('users/${user.uid}/role').onValue.listen((event) {
      final role = event.snapshot.value as String?;
      if (role == null) return;

      if (role == 'doctor') {
        _dbRef
            .child('appointments')
            .orderByChild('doctorId')
            .equalTo(user.uid)
            .onChildAdded
            .listen((event) {
              final appointment = event.snapshot.value as Map;
              _showLocalNotificationForRole(
                title: 'New Appointment',
                body: 'Appointment with ${appointment['patientName']}',
              );
            });
      } else if (role == 'patient') {
        _dbRef
            .child('reports')
            .orderByChild('patientId')
            .equalTo(user.uid)
            .onChildAdded
            .listen((event) {
              final report = event.snapshot.value as Map;
              _showLocalNotificationForRole(
                title: 'New Report Available',
                body: 'Your report from Dr. ${report['doctorName']} is ready.',
              );
            });
      }
    });
  }

  void _showLocalNotificationForRole({
    required String title,
    required String body,
  }) {
    _flutterLocalNotificationsPlugin.show(
      title.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medibridge_channel',
          'MediBridge Notifications',
          channelDescription: 'Channel for MediBridge notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
