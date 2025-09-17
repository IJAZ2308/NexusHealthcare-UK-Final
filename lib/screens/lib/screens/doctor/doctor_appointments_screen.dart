import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final DatabaseReference _appointmentDB = FirebaseDatabase.instance
      .ref()
      .child("appointments");

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;

  // 🔑 Replace with your Firebase Cloud Messaging Server Key
  static const String serverKey = "YOUR_FIREBASE_SERVER_KEY";

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  /// Fetch only this doctor’s appointments
  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final doctor = _auth.currentUser;
      if (doctor == null) return;

      final snapshot = await _appointmentDB.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      List<Map<String, dynamic>> tmp = [];
      if (data != null) {
        data.forEach((key, value) {
          if (value["doctorId"] == doctor.uid) {
            tmp.add({
              "id": key,
              "patientId": value["patientId"] ?? "",
              "doctorId": value["doctorId"] ?? "",
              "doctorName": value["doctorName"] ?? "",
              "specialization": value["specialization"] ?? "",
              "reason": value["reason"] ?? "",
              "timestamp": value["dateTime"] ?? "",
              "status": value["status"] ?? "pending",
              "cancelReason": value["cancelReason"] ?? "",
            });
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _appointments = tmp;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching appointments: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔔 Send FCM Notification to patient
  Future<void> _sendNotification(
    String patientId,
    String title,
    String body,
  ) async {
    try {
      // 1. Get patient’s FCM token from DB
      final tokenSnapshot = await FirebaseDatabase.instance
          .ref()
          .child("users/$patientId/fcmToken")
          .get();

      if (!tokenSnapshot.exists) return;
      final String token = tokenSnapshot.value.toString();

      // 2. Send FCM message
      final response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode({
          "to": token,
          "notification": {"title": title, "body": body, "sound": "default"},
          "priority": "high",
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Failed to send notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Notification error: $e");
    }
  }

  /// Accept appointment
  Future<void> _acceptAppointment(
    String appointmentId,
    String patientId,
  ) async {
    await _appointmentDB.child(appointmentId).update({"status": "accepted"});
    await _sendNotification(
      patientId,
      "Appointment Accepted",
      "Your appointment has been accepted by the doctor.",
    );
    _fetchAppointments();
  }

  /// Cancel appointment
  Future<void> _cancelAppointment(
    String appointmentId,
    String patientId,
  ) async {
    await _appointmentDB.child(appointmentId).update({
      "status": "cancelled",
      "cancelReason": "Cancelled by doctor",
    });
    await _sendNotification(
      patientId,
      "Appointment Cancelled",
      "Your appointment was cancelled by the doctor.",
    );
    _fetchAppointments();
  }

  /// Reschedule appointment
  Future<void> _rescheduleAppointment(
    String appointmentId,
    String patientId,
  ) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await _appointmentDB.child(appointmentId).update({
          "status": "rescheduled",
          "dateTime": newDateTime.toIso8601String(),
        });

        await _sendNotification(
          patientId,
          "Appointment Rescheduled",
          "Your appointment was rescheduled to ${DateFormat("EEE, dd MMM yyyy – hh:mm a").format(newDateTime)}.",
        );

        _fetchAppointments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Appointments")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(child: Text("No appointments found."))
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                final dateTimeObj = DateTime.tryParse(appt["timestamp"] ?? "");
                final formattedDate = dateTimeObj != null
                    ? DateFormat(
                        "EEE, dd MMM yyyy – hh:mm a",
                      ).format(dateTimeObj.toLocal())
                    : "Unknown date";

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("Patient ID: ${appt["patientId"]}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reason: ${appt["reason"]}"),
                        Text("Date: $formattedDate"),
                        Text("Status: ${appt["status"]}"),
                        if (appt["status"] == "cancelled" &&
                            appt["cancelReason"].isNotEmpty)
                          Text(
                            "Reason: ${appt["cancelReason"]}",
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == "accept") {
                          _acceptAppointment(appt["id"], appt["patientId"]);
                        } else if (value == "reschedule") {
                          _rescheduleAppointment(appt["id"], appt["patientId"]);
                        } else if (value == "cancel") {
                          _cancelAppointment(appt["id"], appt["patientId"]);
                        }
                      },
                      itemBuilder: (context) => [
                        if (appt["status"] == "pending") ...[
                          const PopupMenuItem(
                            value: "accept",
                            child: Text("Accept"),
                          ),
                          const PopupMenuItem(
                            value: "reschedule",
                            child: Text("Reschedule"),
                          ),
                          const PopupMenuItem(
                            value: "cancel",
                            child: Text("Cancel"),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
