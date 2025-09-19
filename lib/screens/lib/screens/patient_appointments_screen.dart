import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'doctor/Doctor Module Exports/doctor_list_page.dart';
import 'models/doctor.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final DatabaseReference _appointmentDB = FirebaseDatabase.instance
      .ref()
      .child('appointments');
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  /// ✅ Fetch only the current patient's appointments
  Future<void> _fetchAppointments() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _appointmentDB.once();
      final data = snapshot.snapshot.value;

      List<Map<String, dynamic>> tmp = [];
      if (data != null && data is Map<dynamic, dynamic>) {
        data.forEach((key, value) {
          if (value is Map && value['patientId'] == _currentUserId) {
            tmp.add({
              'id': key,
              'doctorId': value['doctorId'] ?? '',
              'doctorName': value['doctorName'] ?? '',
              'specialization': value['specialization'] ?? '',
              'workingAt': value['workingAt'] ?? 'Unknown Hospital',
              'timestamp': value['dateTime'] ?? '',
              'status': value['status'] ?? 'pending',
              'cancelReason': value['cancelReason'] ?? '',
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
        SnackBar(content: Text("⚠️ Error fetching appointments: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ Cancel an existing appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _appointmentDB.child(appointmentId).update({
        'status': 'cancelled',
        'cancelReason': 'Cancelled by patient',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Appointment cancelled successfully!")),
      );

      await _fetchAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error cancelling appointment: $e")),
      );
    }
  }

  /// ✅ Book a new appointment
  Future<void> _bookNewAppointment() async {
    final Doctor? selectedDoctor = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorListPage()),
    );

    if (selectedDoctor != null && mounted) {
      // 📅 Pick date
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );

      if (selectedDate == null) return;

      // ⏰ Pick time
      final TimeOfDay? selectedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (selectedTime == null) return;

      final DateTime appointmentDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // ✅ Save appointment in Firebase
      final newAppt = {
        'doctorId': selectedDoctor.uid,
        'doctorName': "${selectedDoctor.firstName} ${selectedDoctor.lastName}",
        'specialization': selectedDoctor.category,
        'workingAt': selectedDoctor.workingAt,
        'patientId': _currentUserId,
        'dateTime': appointmentDateTime.toIso8601String(),
        'status': 'pending',
        'cancelReason': '',
      };

      await _appointmentDB.push().set(newAppt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Appointment booked successfully")),
      );

      await _fetchAppointments();
    }
  }

  /// ✅ Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rescheduled':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📅 My Appointments")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(child: Text("No appointments yet."))
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];

                final dateTimeObj = DateTime.tryParse(appt['timestamp'] ?? '');
                final formattedDate = dateTimeObj != null
                    ? DateFormat(
                        'EEE, dd MMM yyyy – hh:mm a',
                      ).format(dateTimeObj.toLocal())
                    : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(appt['doctorName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🏥 ${appt['workingAt']}"),
                        Text("💼 ${appt['specialization']}"),
                        const SizedBox(height: 4),
                        Text("📅 Date: $formattedDate"),
                        Text(
                          "📌 Status: ${appt['status']}",
                          style: TextStyle(
                            color: _getStatusColor(appt['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (appt['status'] == 'cancelled' &&
                            appt['cancelReason'].isNotEmpty)
                          Text(
                            "Reason: ${appt['cancelReason']}",
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    trailing: appt['status'] == 'cancelled'
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              _cancelAppointment(appt['id']);
                            },
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bookNewAppointment,
        icon: const Icon(Icons.add),
        label: const Text("Book Appointment"),
      ),
    );
  }
}
