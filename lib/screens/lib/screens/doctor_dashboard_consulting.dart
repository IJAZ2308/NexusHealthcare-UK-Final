// lib/screens/lib/screens/doctor_dashboard_consulting.dart

import 'package:flutter/material.dart';

class ConsultingDoctorDashboard extends StatelessWidget {
  const ConsultingDoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consulting Doctor Dashboard"),
        backgroundColor: const Color(0xff0064FA),
      ),
      body: const Center(
        child: Text(
          "Welcome, Consulting Doctor!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
