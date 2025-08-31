import 'package:flutter/material.dart';
import 'package:dr_shahin_uk/screens/register_patient.dart';
import 'package:dr_shahin_uk/screens/register_doctor.dart';

class RegisterSelectionScreen extends StatelessWidget {
  const RegisterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Registration Role"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select your role to continue",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              child: const Text("Register as Patient",
                  style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegisterPatientScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Register as Doctor",
                  style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegisterDoctorScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
