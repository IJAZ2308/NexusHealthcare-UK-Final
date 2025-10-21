import 'package:dr_shahin_uk/screens/lib/screens/book_appointment_screen.dart';
import 'package:dr_shahin_uk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/doctor.dart';
import 'doctor_details_page.dart';
import 'doctor_card.dart';
// <-- Add NotificationService
import 'package:firebase_auth/firebase_auth.dart';

class DoctorListPage extends StatefulWidget {
  final bool selectMode; // If true, return doctor on tap

  const DoctorListPage({super.key, this.selectMode = false});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "users",
  );
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child("appointments");
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();

    // Listen for new appointments for this doctor
    _appointmentsRef.onChildAdded.listen((event) {
      final appointment = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      if (_currentUser != null && appointment['doctorId'] == _currentUser.uid) {
        _sendAppointmentNotification(appointment);
      }
    });
  }

  /// Fetch approved doctors
  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    final snapshot = await _dbRef.get();
    List<Doctor> tmpDoctors = [];

    if (snapshot.value != null) {
      final values = snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (value['role'] != null &&
            (value['role'] == 'labDoctor' ||
                value['role'] == 'consultingDoctor') &&
            value['status'] == 'approved') {
          Doctor doctor = Doctor.fromMap(value, key, id: null);
          tmpDoctors.add(doctor);
        }
      });
    }

    setState(() {
      _doctors = tmpDoctors;
      _isLoading = false;
    });
  }

  /// Send notification for new appointment
  Future<void> _sendAppointmentNotification(
    Map<String, dynamic> appointment,
  ) async {
    final patientName = appointment['patientName'] ?? 'A patient';
    final date = appointment['date'] ?? '';
    final time = appointment['time'] ?? '';

    final fcmToken = await _getCurrentUserFcmToken();
    if (fcmToken.isEmpty) return;

    await NotificationService.sendPushNotification(
      fcmToken: fcmToken,
      title: "New Appointment",
      body: "$patientName booked an appointment on $date at $time",
    );
  }

  /// Get current user's FCM token
  Future<String> _getCurrentUserFcmToken() async {
    if (_currentUser == null) return '';
    final snapshot = await _dbRef.child("${_currentUser.uid}/fcmToken").get();
    if (snapshot.exists && snapshot.value != null) {
      return snapshot.value.toString();
    }
    return '';
  }

  void _handleDoctorTap(Doctor doctor) {
    if (widget.selectMode) {
      Navigator.pop(context, doctor);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorDetailPage(doctor: doctor)),
      );
    }
  }

  void _openAppointmentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          doctors: _doctors,
          doctor: _doctors.isNotEmpty
              ? _doctors.first
              : throw StateError('No doctors available'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctors"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openAppointmentForm,
            tooltip: "Book Appointment",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Find your doctor,\nand book an appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Find Doctor by Category',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Add GridView of categories here (omitted for brevity)
                  Expanded(
                    child: _doctors.isEmpty
                        ? const Center(child: Text("No approved doctors yet"))
                        : ListView.builder(
                            itemCount: _doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _doctors[index];
                              return GestureDetector(
                                onTap: () => _handleDoctorTap(doctor),
                                child: DoctorCard(doctor: doctor),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
