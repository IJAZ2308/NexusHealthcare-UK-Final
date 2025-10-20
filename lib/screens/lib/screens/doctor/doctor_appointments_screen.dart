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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'appointments',
  );
  final User? _currentDoctor = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Patients' Appointments",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 3,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "No appointments found.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final List<Map<String, dynamic>> appointments = [];

          // ✅ Filter appointments by current logged-in doctor
          data.forEach((key, value) {
            final appointment = Map<String, dynamic>.from(value);

            if (appointment['doctorId'] == _currentDoctor?.uid) {
              String date = appointment['date'] ?? '';
              String time = appointment['time'] ?? '';

              DateTime? dateTime;
              try {
                dateTime = DateTime.parse(date).add(
                  Duration(
                    hours: int.tryParse(time.split(":")[0]) ?? 0,
                    minutes: int.tryParse(time.split(":")[1]) ?? 0,
                  ),
                );
              } catch (e) {
                dateTime = null;
              }

              if (dateTime != null && dateTime.isAfter(DateTime.now())) {
                appointments.add({
                  'patientName': appointment['patientName'] ?? 'Unknown',
                  'notes': appointment['notes'] ?? '',
                  'dateTime': dateTime,
                });
              }
            }
          });

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                "No upcoming appointments.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          // ✅ Sort appointments by dateTime (nearest first)
          appointments.sort(
            (a, b) => (a['dateTime'] as DateTime).compareTo(
              b['dateTime'] as DateTime,
            ),
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final formattedDate = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(appt['dateTime']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  title: Text(
                    appt['patientName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "🕒 $formattedDate\n📝 ${appt['notes']}",
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.deepPurple.shade300,
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
