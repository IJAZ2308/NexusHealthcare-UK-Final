// lib/screens/update_beds_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateBedsScreen extends StatefulWidget {
  const UpdateBedsScreen({super.key});

  @override
  State<UpdateBedsScreen> createState() => _UpdateBedsScreenState();
}

class _UpdateBedsScreenState extends State<UpdateBedsScreen> {
  final _availableController = TextEditingController();

// ...existing code...
  void updateBeds() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final newBeds = int.tryParse(_availableController.text);

    if (newBeds != null) {
      await FirebaseFirestore.instance.collection('hospitals').doc(uid).update({
        'availableBeds': newBeds,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
    }
  }
// ...existing code...

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Update Bed Availability")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('hospitals').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _availableController.text = data['availableBeds'].toString();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text("Hospital: ${data['name']}"),
                const SizedBox(height: 10),
                TextField(
                  controller: _availableController,
                  decoration:
                      const InputDecoration(labelText: "Available Beds"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateBeds,
                  child: const Text("Update"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
