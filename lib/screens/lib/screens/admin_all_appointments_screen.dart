import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAllAppointmentsScreen extends StatelessWidget {
  const AdminAllAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(title: const Text("All Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.child("appointments").onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found"));
          }

          // Convert appointments map into a list
          final Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final appointments = data.entries.map((entry) {
            final Map<String, dynamic> appointment = Map<String, dynamic>.from(
              entry.value,
            );
            appointment['id'] = entry.key;
            return appointment;
          }).toList();

          // Fetch doctors, patients, hospitals in a FutureBuilder
          return FutureBuilder<DataSnapshot>(
            future: dbRef.get(), // one-time read of full database
            builder: (context, futureSnapshot) {
              if (!futureSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final dbData =
                  futureSnapshot.data!.value as Map<dynamic, dynamic>;

              final doctors = Map<String, dynamic>.from(
                dbData['doctors'] ?? {},
              );
              final patients = Map<String, dynamic>.from(
                dbData['patients'] ?? {},
              );
              final hospitals = Map<String, dynamic>.from(
                dbData['hospitals'] ?? {},
              );

              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];

                  final doctorName =
                      doctors[appt['doctorId']]?['name'] ?? "Unknown Doctor";
                  final patientName =
                      patients[appt['patientId']]?['name'] ?? "Unknown Patient";
                  final hospitalName =
                      hospitals[appt['hospitalId']]?['name'] ??
                      "Unknown Hospital";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("Doctor: $doctorName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Patient: $patientName"),
                          Text("Hospital: $hospitalName"),
                          Text("Date: ${appt['date']}  Time: ${appt['time']}"),
                          Text("Reason: ${appt['reason'] ?? 'N/A'}"),
                          Text("Status: ${appt['status']}"),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
