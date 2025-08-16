// lib/screens/doctor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'update_beds_screen.dart'; // Make sure this path is correct based on your file structure

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Welcome, Doctor! Manage appointments, update bed status etc."),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Update Bed Availability"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateBedsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
