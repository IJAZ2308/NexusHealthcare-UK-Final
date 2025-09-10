import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  Map<String, dynamic> doctors = {};

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  /// Load all doctors into a map for quick lookup
  Future<void> _loadDoctors() async {
    final dbRef = FirebaseDatabase.instance.ref().child("doctors");
    final snapshot = await dbRef.get();
    if (snapshot.exists && snapshot.value != null) {
      final fetchedDoctors = Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
      if (mounted) {
        setState(() {
          doctors = fetchedDoctors;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final dbRef = FirebaseDatabase.instance.ref().child("appointments");

    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.orderByChild("patientId").equalTo(user.uid).onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final snapshotValue = snapshot.data!.snapshot.value;

          if (snapshotValue == null) {
            return const Center(child: Text("No appointments booked"));
          }

          // Convert snapshot to a list
          final appointmentsList = <Map<String, dynamic>>[];
          (snapshotValue as Map<dynamic, dynamic>).forEach((key, value) {
            final data = Map<String, dynamic>.from(value as Map);
            final doctorId = data['doctorId'] ?? "";
            final doctorInfo = doctors[doctorId] ?? {};
            final doctorName =
                "${doctorInfo['firstName'] ?? ''} ${doctorInfo['lastName'] ?? ''}"
                    .trim();
            final doctorCategory = doctorInfo['category'] ?? "";

            appointmentsList.add({
              "id": key,
              "doctorName": doctorName.isEmpty ? "Unknown" : doctorName,
              "doctorCategory": doctorCategory,
              "dateTime":
                  DateTime.tryParse(data['dateTime'] ?? '') ?? DateTime.now(),
              "reason": data['reason'] ?? "",
            });
          });

          // Sort appointments by dateTime
          appointmentsList.sort(
            (a, b) => a['dateTime'].compareTo(b['dateTime']),
          );

          return ListView.builder(
            itemCount: appointmentsList.length,
            itemBuilder: (context, index) {
              final appt = appointmentsList[index];
              final formattedDate = DateFormat(
                'EEE, dd MMM yyyy – hh:mm a',
              ).format(appt['dateTime']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text("${appt['doctorName']}"),
                  subtitle: Text(
                    "Category: ${appt['doctorCategory']}\nDate: $formattedDate\nReason: ${appt['reason']}",
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
