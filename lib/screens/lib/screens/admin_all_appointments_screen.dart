import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllAppointmentsScreen extends StatelessWidget {
  const AdminAllAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Appointments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final data = appointments[index];
              return ListTile(
                title: Text("Doctor: ${data['doctorId']}"),
                subtitle: Text(
                  "Patient: ${data['patientId']}\nDate: ${data['date']} Time: ${data['time']}",
                ),
                trailing: Text(data['status']),
              );
            },
          );
        },
      ),
    );
  }
}
