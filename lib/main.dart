// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MediBridgeApp());
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
        apiKey: "AIzaSyCbcpM-BuqGUtfy071fODqwib_Nhm0BrEY",
        authDomain: "drshahin-uk.firebaseapp.com",
        projectId: "drshahin-uk",
        storageBucket: "drshahin-uk.firebasestorage.app",
        messagingSenderId: "943831581906",
        appId: "1:943831581906:web:a9812cd3ca574d2ee5d90b",
        measurementId: "G-KP31V1Q2P9");
  }
}

class MediBridgeApp extends StatelessWidget {
  const MediBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediBridge360',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
