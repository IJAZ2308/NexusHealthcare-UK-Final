import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LabAppointmentListPage extends StatefulWidget {
  const LabAppointmentListPage({super.key});

  @override
  State<LabAppointmentListPage> createState() => _LabAppointmentListPageState();
}

class _LabAppointmentListPageState extends State<LabAppointmentListPage> {
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child('appointments');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  final String labDoctorId = FirebaseAuth.instance.currentUser!.uid;
  bool _loading = true;
  List<Map<String, String>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _listenForLabAppointments();
  }

  void _listenForLabAppointments() {
    _appointmentsRef.onValue.listen((event) async {
      final snapshot = event.snapshot;
      List<Map<String, String>> loadedAppointments = [];

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (var entry in data.entries) {
          final appointment = Map<String, dynamic>.from(entry.value);

          // Include only those requiring a lab report
          if (appointment['requiresLabReport'] == true) {
            // Show only if assigned to this lab or pending assignment
            if (appointment['labDoctorId'] == labDoctorId ||
                appointment['labDoctorId'] == null) {
              String patientName = "Unknown";
              String treatingDoctorName = "Unknown";

              // Fetch patient name
              if (appointment['patientId'] != null) {
                final patientSnap = await _usersRef
                    .child(appointment['patientId'])
                    .get();
                if (patientSnap.exists) {
                  final pdata = Map<String, dynamic>.from(
                    patientSnap.value as Map,
                  );
                  patientName = pdata['name'] ?? "Unknown";
                }
              }

              // Fetch treating doctor name
              if (appointment['doctorId'] != null) {
                final docSnap = await _usersRef
                    .child(appointment['doctorId'])
                    .get();
                if (docSnap.exists) {
                  final ddata = Map<String, dynamic>.from(docSnap.value as Map);
                  treatingDoctorName = ddata['name'] ?? "Unknown";
                }
              }

              loadedAppointments.add({
                'id': entry.key,
                'patientName': patientName,
                'treatingDoctorName': treatingDoctorName,
                'date': appointment['date'] ?? '',
                'time': appointment['time'] ?? '',
                'status': appointment['status'] ?? '',
              });
            }
          }
        }
      }

      setState(() {
        _appointments = loadedAppointments;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lab Appointments"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(child: Text("No lab appointments available."))
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.biotech_rounded,
                      color: Colors.deepPurple,
                    ),
                    title: Text(
                      appt['patientName']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Requested by: ${appt['treatingDoctorName']}\n"
                        "Date: ${appt['date']} at ${appt['time']}\n"
                        "Status: ${appt['status']}",
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
