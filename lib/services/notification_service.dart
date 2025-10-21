// lib/services/notification_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 🚀 Your FCM server key (keep private, from Firebase console → Project Settings → Cloud Messaging)
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

  /// Initialize FCM & Local Notifications
  Future<void> init() async {
    await Firebase.initializeApp();

    // Request permission (for iOS)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Save the current device token
    await _saveDeviceToken();

    // Start listening to role-based database triggers
    _listenToRoleEvents();
  }

  /// Handle background FCM
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    print('📩 Background message received: ${message.messageId}');
  }

  /// Show local notification
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

  /// Save current device FCM token in RTDB under `users/{uid}/fcmToken`
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

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// 📤 Send FCM Push Notification directly (used in ManagePatientsScreen)
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

  /// 👥 Listen to RTDB events for doctors/patients
  void _listenToRoleEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _dbRef.child('users/${user.uid}/role').onValue.listen((event) {
      final role = event.snapshot.value as String?;
      if (role == null) return;

      if (role == 'doctor') {
        // Doctor: new appointments
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
        // Patient: new reports
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

  /// Helper: show local notification for role-based events
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

  static void initialize() {}
  static void setupFCM() {}
}
