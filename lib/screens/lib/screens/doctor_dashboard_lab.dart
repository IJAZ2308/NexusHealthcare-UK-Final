// lib/screens/lib/screens/doctor_dashboard_lab.dart

import 'package:flutter/material.dart';

class LabDoctorDashboard extends StatelessWidget {
  const LabDoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lab Doctor Dashboard"),
        backgroundColor: const Color(0xff0064FA),
      ),
      body: const Center(
        child: Text(
          "Welcome, Lab Doctor!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
