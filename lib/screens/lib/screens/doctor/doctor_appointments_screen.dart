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

          data.forEach((key, value) {
            final appointment = Map<String, dynamic>.from(value);

            // ✅ Filter by doctorId
            if (appointment['doctorId'] == _currentDoctor?.uid) {
              appointments.add({
                'patient': appointment['name'] ?? 'Unknown Patient',
                'notes': appointment['notes'] ?? '',
                'time': appointment['dateTime'] ?? '',
              });
            }
          });

          if (appointments.isEmpty) {
            return const Center(child: Text("No patients booked yet."));
          }

          // Sort appointments by date/time
          appointments.sort((a, b) {
            final dtA = DateTime.tryParse(a['time']) ?? DateTime.now();
            final dtB = DateTime.tryParse(b['time']) ?? DateTime.now();
            return dtA.compareTo(dtB);
          });

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final time = appt['time'] != ''
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(DateTime.parse(appt['time']))
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Colors.deepPurpleAccent,
                  ),
                  title: Text(appt['patient']),
                  subtitle: Text("Notes: ${appt['notes']}\nTime: $time"),
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
