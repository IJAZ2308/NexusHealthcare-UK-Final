import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PatLabAppointment extends StatefulWidget {
  const PatLabAppointment({super.key});

  @override
  State<PatLabAppointment> createState() => _PatLabAppointmentState();
}

class _PatLabAppointmentState extends State<PatLabAppointment> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _appointmentsDb = FirebaseDatabase.instance
      .ref()
      .child('appointments');
  final DatabaseReference _usersDb = FirebaseDatabase.instance.ref().child(
    'users',
  );

  List<Map<String, String>> _labAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientLabAppointments();
  }

  Future<void> _fetchPatientLabAppointments() async {
    setState(() => _isLoading = true);
    final patientId = _auth.currentUser!.uid;

    final snapshot = await _appointmentsDb
        .orderByChild('patientId') // fetch appointments by patientId
        .equalTo(patientId)
        .get();

    final List<Map<String, String>> loadedAppointments = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var key in data.keys) {
        final appt = Map<String, dynamic>.from(data[key]);

        final requestingDoctorId = appt['requestingDoctorId'] ?? '';
        final labDoctorId = appt['labDoctorId'] ?? '';

        // Fetch requesting doctor name
        String requestingDoctorName = 'Unknown';
        if (requestingDoctorId.isNotEmpty) {
          final doctorSnap = await _usersDb.child(requestingDoctorId).get();
          if (doctorSnap.exists) {
            final doctorData = Map<String, dynamic>.from(
              doctorSnap.value as Map,
            );
            requestingDoctorName = doctorData['name'] ?? 'Doctor';
          }
        }

        // Fetch lab doctor name
        String labDoctorName = 'Unknown';
        if (labDoctorId.isNotEmpty) {
          final labSnap = await _usersDb.child(labDoctorId).get();
          if (labSnap.exists) {
            final labData = Map<String, dynamic>.from(labSnap.value as Map);
            labDoctorName = labData['name'] ?? 'Lab Doctor';
          }
        }

        loadedAppointments.add({
          'labDoctorName': labDoctorName,
          'requestingDoctorName': requestingDoctorName,
          'status': appt['status'] ?? 'Pending',
          'date': appt['date'] ?? '',
          'time': appt['time'] ?? '',
        });
      }
    }

    setState(() {
      _labAppointments = loadedAppointments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Lab Appointments"),
        backgroundColor: const Color(0xff0064FA),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _labAppointments.isEmpty
          ? const Center(child: Text("No lab appointments booked"))
          : ListView.builder(
              itemCount: _labAppointments.length,
              itemBuilder: (context, index) {
                final appt = _labAppointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    title: Text("Lab Doctor: ${appt['labDoctorName']}"),
                    subtitle: Text(
                      "Requested by: ${appt['requestingDoctorName']}\n"
                      "Date: ${appt['date']} ${appt['time']}\n"
                      "Status: ${appt['status']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
