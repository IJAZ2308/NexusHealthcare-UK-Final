import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAllAppointmentsScreen extends StatelessWidget {
  const AdminAllAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref().child("appointments");

    return Scaffold(
      appBar: AppBar(title: const Text("All Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found"));
          }

          // Convert Realtime Database map into list
          final Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final appointments = data.entries.toList();

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index].value as Map;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Doctor: ${appointment['doctorId'] ?? ''}"),
                  subtitle: Text(
                    "Patient: ${appointment['patientId'] ?? ''}\n"
                    "Date: ${appointment['date'] ?? ''}  "
                    "Time: ${appointment['time'] ?? ''}\n"
                    "Reason: ${appointment['reason'] ?? ''}",
                  ),
                  trailing: Text(
                    appointment['status'] ?? 'pending',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
