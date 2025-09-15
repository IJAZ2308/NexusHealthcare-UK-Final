import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAllAppointmentsScreen extends StatefulWidget {
  const AdminAllAppointmentsScreen({super.key});

  @override
  State<AdminAllAppointmentsScreen> createState() =>
      _AdminAllAppointmentsScreenState();
}

class _AdminAllAppointmentsScreenState
    extends State<AdminAllAppointmentsScreen> {
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child("appointments");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Appointments")),
      body: StreamBuilder(
        stream: _appointmentsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found"));
          }

          Map rawData = snapshot.data!.snapshot.value as Map;
          List<Map<String, dynamic>> appointments = [];

          rawData.forEach((key, value) {
            appointments.add({
              "id": key,
              "patientName": value["patientName"] ?? "Unknown",
              "doctorName": value["doctorName"] ?? "Unknown",
              "status": value["status"] ?? "pending",
              "patientId": value["patientId"],
              "doctorId": value["doctorId"],
            });
          });

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appt = appointments[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("${appt["patientName"]} → ${appt["doctorName"]}"),
                  subtitle: Text("Status: ${appt["status"]}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      await _appointmentsRef.child(appt["id"]).update({
                        "status": value,
                      });

                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Appointment marked as $value for ${appt['patientName']}",
                          ),
                        ),
                      );
                      // ✅ Cloud Function will handle sending FCM notification
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "approved",
                        child: Text("Approve ✅"),
                      ),
                      const PopupMenuItem(
                        value: "rejected",
                        child: Text("Reject ❌"),
                      ),
                      const PopupMenuItem(
                        value: "completed",
                        child: Text("Complete ✔"),
                      ),
                    ],
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
