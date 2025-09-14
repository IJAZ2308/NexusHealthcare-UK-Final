import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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

  /// Accept appointment
  Future<void> _acceptAppointment(String appointmentId) async {
    await _appointmentDB.child(appointmentId).update({"status": "accepted"});
    _fetchAppointments();
  }

  /// Cancel appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    await _appointmentDB.child(appointmentId).update({
      "status": "cancelled",
      "cancelReason": "Cancelled by doctor",
    });
    _fetchAppointments();
  }

  /// Reschedule appointment
  Future<void> _rescheduleAppointment(String appointmentId) async {
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
                          _acceptAppointment(appt["id"]);
                        } else if (value == "reschedule") {
                          _rescheduleAppointment(appt["id"]);
                        } else if (value == "cancel") {
                          _cancelAppointment(appt["id"]);
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
