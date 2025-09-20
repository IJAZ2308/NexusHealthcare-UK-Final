import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:dr_shahin_uk/screens/auth/login_screen.dart';
import 'package:dr_shahin_uk/services/database_service.dart';

final DatabaseService dbService = DatabaseService();

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

// ------------------------ FIREBASE OPTIONS ------------------------
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

// ------------------------ AUTH SERVICE ------------------------
// ------------------------ AUTH SERVICE ------------------------
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Cloudinary details
  final String cloudName = "dij8c34qm"; // ✅ hardcoded cloud name
  final String uploadPreset = "medi360_unsigned"; // ✅ your unsigned preset

  /// Upload license to Cloudinary
  Future<String?> uploadLicense(File licenseFile) async {
    try {
      final Uri uploadUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/dij8c34qm/auto/upload", // ✅ hardcoded
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

  /// Register user (saves licenseUrl if doctor)
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? licenseUrl,
    File? licenseFile,
    required String specialization,
    required bool isVerified,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.child("users").child(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'isVerified': role == 'doctor' ? false : true,
        'licenseUrl': licenseUrl ?? '',
        'specialization': role == 'doctor' ? specialization : '',
      });

      return true;
    } on FirebaseAuthException catch (e) {
      developer.log("FirebaseAuth error", error: e.message);
      return false;
    } catch (e) {
      developer.log("Register error", error: e);
      return false;
    }
  }

  /// Login
  Future<String?> login(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final DataSnapshot snapshot = await _db
          .child("users")
          .child(result.user!.uid)
          .get();

      if (!snapshot.exists) return null;

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      if (data['role'] == 'doctor' && data['isVerified'] == false) {
        return null; // Doctor must be verified by admin
      }

      return data['role'] as String?;
    } catch (e) {
      developer.log("Login error", error: e);
      return null;
    }
  }
}

// ------------------------ FCM BACKGROUND HANDLER ------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log("🔔 Handling background message: ${message.messageId}");
}

// ------------------------ MODIFY MAIN TO INIT FCM ------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// ------------------------ SAVE FCM TOKEN ------------------------
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

// ------------------------ FOREGROUND FCM LISTENER ------------------------
void setupFCMListeners(BuildContext context) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final title = message.notification!.title ?? "";
      final body = message.notification!.body ?? "";

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("$title\n$body")));
    }
  });
}
