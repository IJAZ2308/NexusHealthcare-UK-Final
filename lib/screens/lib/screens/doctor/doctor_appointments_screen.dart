import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child('appointments');

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  /// Function to update appointment status
  void _updateStatus(String appointmentId, String status) {
    _appointmentsRef.child(appointmentId).update({'status': status});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Appointment $status")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _appointmentsRef.orderByChild('doctorId').equalTo(uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found."));
          }

          final Map<dynamic, dynamic> appointmentsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final appointments = appointmentsMap.entries.map((entry) {
            final data = Map<String, dynamic>.from(entry.value);
            data['id'] = entry.key; // keep Firebase key
            return data;
          }).toList();

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final data = appointments[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Patient ID: ${data['patientId']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: ${data['date']}"),
                      Text("Time: ${data['time']}"),
                      Text("Reason: ${data['reason']}"),
                      Text("Status: ${data['status']}"),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: data['status'] == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              tooltip: 'Accept',
                              onPressed: () =>
                                  _updateStatus(data['id'], 'accepted'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Cancel',
                              onPressed: () =>
                                  _updateStatus(data['id'], 'cancelled'),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(), // No buttons if not pending
                ),
              );
            },
          );
        },
      ),
    );
  }
}
