import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:dr_shahin_uk/screens/lib/screens/doctor/Doctor%20Module%20Exports/doctor_list_page.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/Doctor%20Module%20Exports/doctor_details_page.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';

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

  /// Fetch only the current patient's appointments
  Future<void> _fetchAppointments() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _appointmentDB.once();
      final data = snapshot.snapshot.value;

      List<Map<String, dynamic>> tmp = [];
      if (data != null) {
        final map = data as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          // ✅ Only include appointments for this patient
          if (value['patientId'] == _currentUserId) {
            tmp.add({
              'id': key,
              'doctorId': value['doctorId'] ?? '',
              'doctorName': value['doctorName'] ?? '',
              'specialization': value['specialization'] ?? '',
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
        SnackBar(content: Text("Error fetching appointments: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cancel an existing appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _appointmentDB.child(appointmentId).update({
        'status': 'cancelled',
        'cancelReason': 'Cancelled by patient',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment cancelled successfully!")),
      );

      await _fetchAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cancelling appointment: $e")),
      );
    }
  }

  /// Navigate to doctor list → doctor details → confirm appointment
  Future<void> _bookNewAppointment() async {
    final Doctor? selectedDoctor = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorListPage()),
    );

    if (selectedDoctor != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDetailPage(doctor: selectedDoctor),
        ),
      );

      if (!mounted) return;
      await _fetchAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
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

                // Color coding for status
                Color statusColor;
                switch (appt['status']) {
                  case 'accepted':
                    statusColor = Colors.green;
                    break;
                  case 'rescheduled':
                    statusColor = Colors.orange;
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.blueGrey;
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(appt['doctorName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt['specialization']),
                        const SizedBox(height: 4),
                        Text("Date: $formattedDate"),
                        Text(
                          "Status: ${appt['status']}",
                          style: TextStyle(color: statusColor),
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
                            icon: const Icon(Icons.cancel, color: Colors.red),
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
