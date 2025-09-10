import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAllAppointmentsScreen extends StatelessWidget {
  const AdminAllAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(title: const Text("All Appointments & Bed Status")),
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
          });

          return FutureBuilder<DataSnapshot>(
            future: dbRef
                .get(), // one-time read for doctors, patients, hospitals
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

              // Group appointments by doctorId
              final Map<String, List<Map<String, dynamic>>> groupedByDoctor =
                  {};
              for (var appt in appointments) {
                final doctorId = appt['doctorId'] ?? 'unknown';
                if (!groupedByDoctor.containsKey(doctorId)) {
                  groupedByDoctor[doctorId] = [];
                }
                groupedByDoctor[doctorId]!.add(appt);
              }

              return ListView(
                children: [
                  // Bed availability section
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hospital Bed Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...hospitals.entries.map((entry) {
                          final hospital = Map<String, dynamic>.from(
                            entry.value,
                          );
                          final name = hospital['name'] ?? 'Unknown Hospital';
                          final totalBeds = hospital['totalBeds'] ?? 0;
                          final occupiedBeds = hospital['occupiedBeds'] ?? 0;
                          final availableBeds = totalBeds - occupiedBeds;

                          return Card(
                            color: availableBeds <= 0
                                ? Colors.red[100]
                                : Colors.lightBlue[50],
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Total Beds: $totalBeds\nOccupied Beds: $occupiedBeds\nAvailable Beds: $availableBeds",
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const Divider(thickness: 2),

                  // Appointments grouped by doctor
                  ...groupedByDoctor.entries.map((entry) {
                    final doctorId = entry.key;
                    final doctorName =
                        doctors[doctorId]?['name'] ?? "Unknown Doctor";
                    final doctorAppointments = entry.value;

                    return ExpansionTile(
                      title: Text(
                        "Doctor: $doctorName (${doctorAppointments.length})",
                      ),
                      children: [
                        ...doctorAppointments.map((appt) {
                          final patientName =
                              patients[appt['patientId']]?['name'] ??
                              "Unknown Patient";
                          final hospitalName =
                              hospitals[appt['hospitalId']]?['name'] ??
                              "Unknown Hospital";

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text("Patient: $patientName"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Hospital: $hospitalName"),
                                  Text(
                                    "Date: ${appt['date']}  Time: ${appt['time']}",
                                  ),
                                  Text("Reason: ${appt['reason'] ?? 'N/A'}"),
                                  Text("Status: ${appt['status']}"),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
