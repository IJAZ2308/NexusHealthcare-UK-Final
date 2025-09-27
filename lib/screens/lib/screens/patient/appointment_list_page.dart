import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'appointments',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.teal,
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
            appointments.add({
              'doctor': appointment['doctorName'] ?? 'Unknown',
              'specialization': appointment['specialization'] ?? 'General',
              'time': appointment['dateTime'] ?? '',
            });
          });

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
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text(appt['doctor']),
                  subtitle: Text("${appt['specialization']} • $time"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
