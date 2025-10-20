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
    _fetchLabAppointments();
  }

  Future<void> _fetchLabAppointments() async {
    setState(() => _loading = true);

    final snapshot = await _appointmentsRef
        .orderByChild('requiresLabReport')
        .equalTo(true)
        .get();

    final List<Map<String, String>> loadedAppointments = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final appointment = Map<String, dynamic>.from(entry.value);

        // Only include appointments assigned to this lab doctor or pending
        if (appointment['labDoctorId'] == labDoctorId ||
            appointment['labDoctorId'] == null) {
          String patientName = "Unknown";
          String treatingDoctorName = "Unknown";

          // Get patient name
          if (appointment['patientId'] != null) {
            final patientSnapshot = await _usersRef
                .child(appointment['patientId'])
                .get();
            if (patientSnapshot.exists) {
              final patientData = Map<String, dynamic>.from(
                patientSnapshot.value as Map,
              );
              patientName = patientData['name'] ?? "Unknown";
            }
          }

          // Get doctor who requested report (treating doctor)
          if (appointment['doctorId'] != null) {
            final doctorSnapshot = await _usersRef
                .child(appointment['doctorId'])
                .get();
            if (doctorSnapshot.exists) {
              final doctorData = Map<String, dynamic>.from(
                doctorSnapshot.value as Map,
              );
              treatingDoctorName = doctorData['name'] ?? "Unknown";
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

    setState(() {
      _appointments = loadedAppointments;
      _loading = false;
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
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(appt['patientName']!),
                    subtitle: Text(
                      "Requested by: ${appt['treatingDoctorName']}\nDate: ${appt['date']} at ${appt['time']}\nStatus: ${appt['status']}",
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
