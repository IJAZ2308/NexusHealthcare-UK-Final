// lib/screens/manage_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() =>
      _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'appointments',
  );

  Future<void> _updateStatus(String appointmentId, String status) async {
    await _dbRef.child(appointmentId).update({'status': status});
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    await _dbRef.child(appointmentId).remove();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment deleted successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found"));
          }

          final Map<dynamic, dynamic> appointmentsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> appointments = appointmentsMap
              .entries
              .map((e) {
                final data = e.value as Map<dynamic, dynamic>;
                data['appointmentId'] = e.key;
                return data;
              })
              .toList();

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final data = appointments[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${data['doctorName']} - ${data['patientName']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hospital: ${data['hospitalId']}"),
                      Text("Specialty: ${data['specialty']}"),
                      Text("Date: ${data['date']} ${data['time']}"),
                      Text("Status: ${data['status']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            _updateStatus(data['appointmentId'], value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "booked",
                            child: Text("Booked"),
                          ),
                          const PopupMenuItem(
                            value: "pending",
                            child: Text("Pending"),
                          ),
                          const PopupMenuItem(
                            value: "cancelled",
                            child: Text("Cancelled"),
                          ),
                        ],
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteAppointment(data['appointmentId']),
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
