import 'package:flutter/material.dart';
import 'register_patient.dart';
import 'register_doctor.dart';

class RegisterSelectionScreen extends StatelessWidget {
  const RegisterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Registration Role")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text("Register as Patient"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPatientScreen()),
                );
              },
            ),
            ElevatedButton(
              child: Text("Register as Doctor"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterDoctorScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
