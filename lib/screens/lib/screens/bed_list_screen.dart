// lib/screens/bed_list_screen.dart

import 'package:dr_shahin_uk/screens/lib/screens/models/bed_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BedListScreen extends StatelessWidget {
  const BedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bed Availability")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final hospitals = snapshot.data!.docs
              .map((doc) => HospitalBed.fromMap(
                  doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final h = hospitals[index];
              return Card(
                child: ListTile(
                  title: Text(h.name),
                  subtitle:
                      Text("Available Beds: ${h.availableBeds}/${h.totalBeds}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
