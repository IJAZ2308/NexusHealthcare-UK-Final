import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase DB Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase DB Test')),
        body: const DatabaseDemo(),
      ),
    );
  }
}

class DatabaseDemo extends StatefulWidget {
  const DatabaseDemo({super.key});

  @override
  State<DatabaseDemo> createState() => _DatabaseDemoState();
}

class _DatabaseDemoState extends State<DatabaseDemo> {
  final databaseRef = FirebaseDatabase.instance.ref("users");
  String output = "";

  @override
  void initState() {
    super.initState();
    writeData();
    readData();
  }

  void writeData() {
    databaseRef.child("user1").set({
      "name": "Shahin",
      "email": "shahin@example.com",
    });
  }

  void readData() async {
    final snapshot = await databaseRef.child("user1").get();
    if (snapshot.exists) {
      setState(() {
        output = snapshot.value.toString();
      });
    } else {
      setState(() {
        output = "No data found.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(output, style: const TextStyle(fontSize: 20)),
    );
  }
}

// Your Firebase project configuration
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyCbcpM-BuqGUtfy071fODqwib_Nhm0BrEY",
      authDomain: "drshahin-uk.firebaseapp.com",
      projectId: "drshahin-uk",
      storageBucket: "drshahin-uk.firebasestorage.app",
      messagingSenderId: "943831581906",
      appId: "1:943831581906:web:a9812cd3ca574d2ee5d90b",
      measurementId: "G-KP31V1Q2P9",
    );
  }
}
