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

  void _updateStatus(String appointmentId, String status) {
    _appointmentsRef.child(appointmentId).update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
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
          final List<Map<dynamic, dynamic>> appointments = appointmentsMap
              .entries
              .map((e) {
                final data = e.value as Map<dynamic, dynamic>;
                data['id'] = e.key; // Save key for updates
                return data;
              })
              .toList();

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final data = appointments[index];

              return ListTile(
                title: Text("Patient ID: ${data['patientId']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: ${data['date']}  Time: ${data['time']}"),
                    Text("Reason: ${data['reason']}"),
                    Text("Status: ${data['status']}"),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['status'] == 'pending') ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Accept',
                        onPressed: () {
                          _updateStatus(data['id'], 'accepted');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Cancel',
                        onPressed: () {
                          _updateStatus(data['id'], 'cancelled');
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
