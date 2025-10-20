// lib/services/notification_service.dart
// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Initialize FCM & Local Notifications
  Future<void> init() async {
    await Firebase.initializeApp();

    // Request permission (iOS)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Save token to RTDB
    await _saveDeviceToken();

    // Listen to role-specific events
    _listenToRoleEvents();
  }

  /// Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    print('Background message received: ${message.messageId}');
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
            'medbridge_channel',
            'MediBridge Notifications',
            channelDescription: 'Channel for MediBridge notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  /// Save FCM token in RTDB under current user
  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _dbRef.child('users/${user.uid}/fcmToken').set(token);
        // ignore: duplicate_ignore
        // ignore: avoid_print
        print('FCM token saved for user: ${user.uid}');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// Listen to role-specific events in RTDB
  void _listenToRoleEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user role from RTDB
    _dbRef.child('users/${user.uid}/role').onValue.listen((event) {
      final role = event.snapshot.value as String?;
      if (role == null) return;

      if (role == 'doctor') {
        // Listen to new appointments for this doctor
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
        // Listen to report uploads for this patient
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

  /// Helper to show notifications for role-specific RTDB events
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
          'VitaLink_channel',
          'VitaLink Notifications',
          channelDescription: 'Channel for VitaLink notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static void initialize() {}

  static void setupFCM() {}
}
