import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentListPage extends StatefulWidget {
  const DoctorAppointmentListPage({super.key});

  @override
  State<DoctorAppointmentListPage> createState() =>
      _DoctorAppointmentListPageState();
}

class _DoctorAppointmentListPageState extends State<DoctorAppointmentListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'appointments',
  );
  final User? _currentDoctor = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Patients Appointments"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found."));
          }

          final Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> appointments = [];

          // Build appointments list filtered by current doctor
          data.forEach((key, value) {
            final appointment = Map<String, dynamic>.from(value);

            if (appointment['doctorId'] == _currentDoctor?.uid) {
              appointments.add({
                'patient': appointment['patientName'] ?? 'Unknown Patient',
                'notes': appointment['notes'] ?? '',
                'date': appointment['date'] ?? '',
                'time': appointment['time'] ?? '',
              });
            }
          });

          if (appointments.isEmpty) {
            return const Center(child: Text("No patients booked yet."));
          }

          // Sort appointments by date & time
          appointments.sort((a, b) {
            DateTime dtA = DateTime.tryParse(a['date']) ?? DateTime.now();
            DateTime dtB = DateTime.tryParse(b['date']) ?? DateTime.now();

            // Combine with time
            if (a['time'] != '') {
              final parts = a['time'].split(":");
              dtA = dtA.add(
                Duration(
                  hours: int.tryParse(parts[0]) ?? 0,
                  minutes: int.tryParse(parts[1]) ?? 0,
                ),
              );
            }
            if (b['time'] != '') {
              final parts = b['time'].split(":");
              dtB = dtB.add(
                Duration(
                  hours: int.tryParse(parts[0]) ?? 0,
                  minutes: int.tryParse(parts[1]) ?? 0,
                ),
              );
            }
            return dtA.compareTo(dtB);
          });

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];

              String displayTime = 'N/A';
              if (appt['date'] != '' && appt['time'] != '') {
                final dateTime = DateTime.parse(appt['date']).add(
                  Duration(
                    hours: int.parse(appt['time'].split(":")[0]),
                    minutes: int.parse(appt['time'].split(":")[1]),
                  ),
                );
                displayTime = DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(dateTime);
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Colors.deepPurpleAccent,
                  ),
                  title: Text(appt['patient']),
                  subtitle: Text("Notes: ${appt['notes']}\nTime: $displayTime"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
