import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        AndroidInitializationSettings,
        FlutterLocalNotificationsPlugin,
        AndroidNotificationChannel,
        Importance,
        AndroidNotificationDetails,
        NotificationDetails,
        Priority,
        AndroidFlutterLocalNotificationsPlugin,
        InitializationSettings;
import 'package:http/http.dart' as http;

import 'package:dr_shahin_uk/screens/auth/login_screen.dart';
import 'package:dr_shahin_uk/services/database_service.dart';

final DatabaseService dbService = DatabaseService();

/// ------------------------ LOCAL NOTIFICATIONS ------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Android notification channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

/// ------------------------ MAIN APP ------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediBridge360',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

/// ------------------------ FIREBASE OPTIONS ------------------------
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyCbcpM-BuqGUtfy071fODqwib_Nhm0BrEY",
      authDomain: "drshahin-uk.firebaseapp.com",
      projectId: "drshahin-uk",
      storageBucket: "drshahin-uk.appspot.com",
      messagingSenderId: "943831581906",
      appId: "1:943831581906:web:a9812cd3ca574d2ee5d90b",
      measurementId: "G-KP31V1Q2P9",
      databaseURL: "https://drshahin-uk-default-rtdb.firebaseio.com/",
    );
  }
}

/// ------------------------ AUTH SERVICE ------------------------
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final String cloudName = "dij8c34qm";
  final String uploadPreset = "medi360_unsigned";

  Future<String?> uploadLicense(File licenseFile) async {
    try {
      final Uri uploadUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/dij8c34qm/auto/upload",
      );

      final http.MultipartRequest request =
          http.MultipartRequest("POST", uploadUrl)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', licenseFile.path),
            );

      final http.StreamedResponse response = await request.send();
      final http.Response responseData = await http.Response.fromStream(
        response,
      );

      developer.log("Cloudinary response: ${responseData.body}");

      final Map<String, dynamic> data =
          jsonDecode(responseData.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['secure_url'] != null) {
        return data['secure_url'] as String;
      } else {
        throw Exception(
          "Cloudinary upload failed: ${data['error'] ?? responseData.body}",
        );
      }
    } catch (e) {
      developer.log("Cloudinary upload error", error: e);
      return null;
    }
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? licenseUrl,
    File? licenseFile,
    required String specialization,
    required bool isVerified,
    required String doctorType,
    required String s, // labDoctor / consultingDoctor
  }) async {
    try {
      // 1️⃣ Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user!.uid;

      if (role == 'doctor') {
        // 2️⃣ Save doctor info under "doctors" node
        final userRef = _db.child("doctors").child(uid);

        await userRef.set({
          'uid': uid,
          'firstName': name, // optionally split firstName / lastName
          'email': email,
          'role': role,
          'doctorRole': s, // labDoctor / consultingDoctor
          'licenseUrl': licenseUrl ?? '',
          'specialization': specialization,
          'status': doctorType, // pending
          'isVerified': isVerified,
          'fcmToken': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        // 2️⃣ Save normal users under "users" node
        final userRef = _db.child("users").child(uid);

        await userRef.set({
          'uid': uid,
          'name': name,
          'email': email,
          'role': role,
          'isVerified': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // 3️⃣ Save FCM token after registration
      await saveUserToken();

      return true;
    } catch (e) {
      developer.log("Register error", error: e);
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DataSnapshot snapshot;

      // First check in "doctors" node
      snapshot = await _db.child("doctors").child(result.user!.uid).get();

      if (snapshot.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          snapshot.value as Map,
        );

        if (data['isVerified'] == false) {
          return null; // Doctor must be verified
        }

        // Save FCM token after login
        await saveUserToken();

        return data['role'] as String?;
      }

      // Otherwise check in "users" node
      snapshot = await _db.child("users").child(result.user!.uid).get();

      if (!snapshot.exists) return null;

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      // Save FCM token after login
      await saveUserToken();

      return data['role'] as String?;
    } catch (e) {
      developer.log("Login error", error: e);
      return null;
    }
  }

  /// ------------------------ FCM BACKGROUND HANDLER ------------------------
  Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log("🔔 Handling background message: ${message.messageId}");

    _showLocalNotification(message);
  }

  /// ------------------------ LOCAL NOTIFICATION HELPER ------------------------
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null && Platform.isAndroid) {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  /// ------------------------ SAVE FCM TOKEN ------------------------
  Future<void> saveUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseDatabase.instance.ref("users/${user.uid}").update({
        "fcmToken": token,
      });
      developer.log("🔑 Saved FCM Token: $token");
    }
  }

  /// ------------------------ FOREGROUND FCM LISTENER ------------------------
  void setupFCMListeners(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  /// ------------------------ MAIN FUNCTION ------------------------
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(const MyApp());
  }
}
