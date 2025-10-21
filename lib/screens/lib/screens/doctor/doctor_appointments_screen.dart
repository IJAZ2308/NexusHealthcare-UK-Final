import 'package:dr_shahin_uk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
// <-- Import NotificationService

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
  late Stream<DatabaseEvent> _appointmentStream;

  @override
  void initState() {
    super.initState();
    _appointmentStream = _dbRef.onChildAdded;

    // Listen for new appointments and send notifications
    _appointmentStream.listen((event) {
      final appointment = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      if (appointment['doctorId'] == _currentDoctor?.uid) {
        _sendAppointmentNotification(appointment);
      }
    });
  }

  /// 🔔 Send push notification for new appointment
  Future<void> _sendAppointmentNotification(
    Map<String, dynamic> appointment,
  ) async {
    final patientName = appointment['patientName'] ?? 'A patient';
    final date = appointment['date'] ?? '';
    final time = appointment['time'] ?? '';

    await NotificationService.sendPushNotification(
      fcmToken: await _getDoctorFcmToken(),
      title: "New Appointment Scheduled",
      body: "$patientName has booked an appointment on $date at $time.",
    );
  }

  /// Get FCM token of logged-in doctor
  Future<String> _getDoctorFcmToken() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${_currentDoctor?.uid}/fcmToken')
        .get();
    if (snapshot.exists && snapshot.value != null) {
      return snapshot.value.toString();
    }
    return '';
  }

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
        stream: FirebaseDatabase.instance.ref('appointments').onValue,
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

          appointments.sort(
            (a, b) => (a['dateTime'] as DateTime).compareTo(
              a['dateTime'] as DateTime,
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
