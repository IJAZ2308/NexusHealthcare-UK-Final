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
    _fetchLabAppointments();
  }

  Future<void> _fetchLabAppointments() async {
    setState(() => _isLoading = true);
    final labDoctorId = _auth.currentUser!.uid;

    final snapshot = await _appointmentsDb
        .orderByChild('labDoctorId') // field that stores assigned lab doctor
        .equalTo(labDoctorId)
        .get();

    final List<Map<String, String>> loadedAppointments = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var key in data.keys) {
        final appt = Map<String, dynamic>.from(data[key]);
        final patientId = appt['patientId'] ?? '';
        final requestingDoctorId = appt['requestingDoctorId'] ?? '';

        // Fetch patient name
        String patientName = 'Unknown';
        final patientSnap = await _usersDb.child(patientId).get();
        if (patientSnap.exists) {
          final patientData = Map<String, dynamic>.from(
            patientSnap.value as Map,
          );
          patientName = patientData['name'] ?? 'Patient';
        }

        // Fetch requesting doctor name
        String doctorName = 'Unknown';
        final doctorSnap = await _usersDb.child(requestingDoctorId).get();
        if (doctorSnap.exists) {
          final doctorData = Map<String, dynamic>.from(doctorSnap.value as Map);
          doctorName = doctorData['name'] ?? 'Doctor';
        }

        loadedAppointments.add({
          'patientName': patientName,
          'doctorName': doctorName,
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
        title: const Text("Lab Appointments"),
        backgroundColor: const Color(0xff0064FA),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _labAppointments.isEmpty
          ? const Center(child: Text("No lab appointments assigned"))
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
                    title: Text(appt['patientName']!),
                    subtitle: Text(
                      "Requested by: ${appt['doctorName']}\nDate: ${appt['date']} ${appt['time']}\nStatus: ${appt['status']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
