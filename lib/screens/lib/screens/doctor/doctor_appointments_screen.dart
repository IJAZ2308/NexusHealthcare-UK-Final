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
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child('appointments');
  Map<String, dynamic> patients = {};
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  /// Load all patients for displaying full info
  Future<void> _loadPatients() async {
    final dbRef = FirebaseDatabase.instance.ref().child("patients");
    final snapshot = await dbRef.get();
    if (snapshot.exists && snapshot.value != null && mounted) {
      final Map<String, dynamic> fetchedPatients = Map<String, dynamic>.from(
        snapshot.value as Map,
      );
      setState(() {
        patients = fetchedPatients;
      });
    }
  }

  /// Update appointment status directly (accept only)
  Future<void> _updateStatus(String appointmentId, String status) async {
    await _appointmentsRef.child(appointmentId).update({'status': status});
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Appointment $status")));
  }

  /// Cancel appointment with reason
  void _cancelAppointment(String appointmentId) {
    final reasonController = TextEditingController();

    if (!mounted) return; // ✅ check before using context
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Enter cancellation reason",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                await _appointmentsRef.child(appointmentId).update({
                  'status': 'cancelled',
                  'cancelReason': reason,
                });

                if (!mounted) return; // ✅ safe before using context
                // ignore: use_build_context_synchronously
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Appointment cancelled")),
                );
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// Reschedule appointment
  Future<void> _rescheduleAppointment(
    String appointmentId,
    DateTime oldDate,
  ) async {
    if (!mounted) return; // ✅ safe before using context
    final newDate = await showDatePicker(
      context: context,
      initialDate: oldDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate == null) return;

    if (!mounted) return;
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(oldDate),
    );
    if (newTime == null) return;

    final newDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );

    await _appointmentsRef.child(appointmentId).update({
      'status': 'rescheduled',
      'dateTime': newDateTime.toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Appointment rescheduled")));
  }

  /// Show detailed patient info
  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final patientId = appointment['patientId'] ?? '';
    final patientInfo = patients[patientId] ?? {};

    if (!mounted) return; // ✅ safe before using context
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          patientInfo['firstName'] != null
              ? "${patientInfo['firstName']} ${patientInfo['lastName']}"
              : "Patient Info",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patientInfo['email'] != null)
              Text("Email: ${patientInfo['email']}"),
            if (patientInfo['phoneNumber'] != null)
              Text("Phone: ${patientInfo['phoneNumber']}"),
            Text("Reason: ${appointment['reason'] ?? ''}"),
            Text("Date & Time: ${appointment['dateTime'] ?? ''}"),
            Text("Status: ${appointment['status'] ?? ''}"),
            if (appointment['cancelReason'] != null)
              Text("Cancel Reason: ${appointment['cancelReason']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Appointments")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _appointmentsRef.orderByChild('doctorId').equalTo(uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No appointments found."));
          }

          final Map<dynamic, dynamic> appointmentsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final appointments = appointmentsMap.entries.map((entry) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            data['id'] = entry.key;

            final patientId = data['patientId'] ?? '';
            final patientInfo = patients[patientId] ?? {};
            data['patientName'] =
                "${patientInfo['firstName'] ?? ''} ${patientInfo['lastName'] ?? ''}"
                    .trim();

            data['dateTimeObj'] =
                DateTime.tryParse(data['dateTime'] ?? '') ?? DateTime.now();

            return data;
          }).toList();

          final now = DateTime.now();
          final upcomingAppointments = appointments
              .where((appt) => appt['dateTimeObj'].isAfter(now))
              .toList();

          upcomingAppointments.sort(
            (a, b) => a['dateTimeObj'].compareTo(b['dateTimeObj']),
          );

          if (upcomingAppointments.isEmpty) {
            return const Center(child: Text("No upcoming appointments."));
          }

          return ListView.builder(
            itemCount: upcomingAppointments.length,
            itemBuilder: (context, index) {
              final appt = upcomingAppointments[index];
              final formattedDate = DateFormat(
                'EEE, dd MMM yyyy – hh:mm a',
              ).format(appt['dateTimeObj']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    appt['patientName'].isNotEmpty
                        ? appt['patientName']
                        : "Patient ID: ${appt['patientId']}",
                  ),
                  subtitle: Text(
                    "Date & Time: $formattedDate\n"
                    "Reason: ${appt['reason'] ?? ''}\n"
                    "Status: ${appt['status'] ?? ''}",
                  ),
                  isThreeLine: true,
                  onTap: () => _showAppointmentDetails(appt),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (appt['status'] == 'pending') ...[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Accept',
                          onPressed: () =>
                              _updateStatus(appt['id'], 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Cancel',
                          onPressed: () => _cancelAppointment(appt['id']),
                        ),
                      ],
                      if (appt['status'] == 'accepted')
                        IconButton(
                          icon: const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                          ),
                          tooltip: 'Reschedule',
                          onPressed: () => _rescheduleAppointment(
                            appt['id'],
                            appt['dateTimeObj'],
                          ),
                        ),
                    ],
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
