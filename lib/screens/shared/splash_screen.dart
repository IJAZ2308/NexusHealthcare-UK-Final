import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/admin_dashboard.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor_dashboard_lab.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor_dashboard_consulting.dart';
import 'package:dr_shahin_uk/screens/lib/screens/patient_dashboard.dart';
import 'verify_pending.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref(); // Realtime DB root

  @override
  void initState() {
    super.initState();
    navigateUser();
  }

  Future<void> navigateUser() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final snapshot = await _db.child("users/${user.uid}").get();
    if (!snapshot.exists) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final String role = data['role'] ?? '';
    final bool verified = data['isVerified'] ?? true; // doctor verification

    if (!mounted) return;

    switch (role) {
      case 'admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
        break;
      case 'labDoctor':
        if (!verified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerifyPending()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LabDoctorDashboard()),
          );
        }
        break;
      case 'consultingDoctor':
        if (!verified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerifyPending()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ConsultingDoctorDashboard(),
            ),
          );
        }
        break;
      case 'patient':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
        );
        break;
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "MediBridge360",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
