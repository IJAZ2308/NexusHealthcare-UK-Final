// lib/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void verifyDoctor(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isVerified': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctors = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: StreamBuilder(
        stream: doctors,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text(doc['email']),
                trailing: ElevatedButton(
                  onPressed: () => verifyDoctor(doc.id),
                  child: const Text("Verify"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
