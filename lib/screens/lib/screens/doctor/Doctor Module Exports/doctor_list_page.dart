import 'package:dr_shahin_uk/screens/lib/screens/book_appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dr_shahin_uk/services/notification_service.dart';
import '../../models/doctor.dart';

import 'doctor_details_page.dart';
import 'doctor_card.dart';

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
  String _selectedCategory = 'All';

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'image': 'assets/images/grid.png'},
    {'name': 'Child', 'image': 'assets/images/child.png'},
    {'name': 'Dental', 'image': 'assets/images/dental.png'},
    {'name': 'ENT', 'image': 'assets/images/ent.png'},
    {'name': 'Eye', 'image': 'assets/images/eye.png'},
    {'name': 'Heart', 'image': 'assets/images/heart.png'},
    {'name': 'Neuro', 'image': 'assets/images/neuro.png'},
    {'name': 'Surgery', 'image': 'assets/images/surgery.png'},
    {'name': 'Ortho', 'image': 'assets/images/ortho.png'},
    {'name': 'Plastic', 'image': 'assets/images/plastic.png'},
    {'name': 'Gyn', 'image': 'assets/images/gyn.png'},
    {'name': 'Onco', 'image': 'assets/images/onco.png'},
    {'name': 'Urology', 'image': 'assets/images/urology.png'},
    {'name': 'Public', 'image': 'assets/images/publichealth.png'},
    {'name': 'Work', 'image': 'assets/images/work.png'},
    {'name': 'Vascular', 'image': 'assets/images/vascular.png'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();

    // Listen for new appointments to send doctor notifications
    _appointmentsRef.onChildAdded.listen((event) {
      final appointment = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      if (_currentUser != null && appointment['doctorId'] == _currentUser.uid) {
        _sendAppointmentNotification(appointment);
      }
    });
  }

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

  void _openAppointmentForm(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BookAppointmentScreen(doctors: [doctor], doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _selectedCategory == 'All'
        ? _doctors
        : _doctors
              .where(
                (d) => d.specializations
                    .map((s) => s.toLowerCase())
                    .contains(_selectedCategory.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Doctors")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find your doctor,\nand book an appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Find Doctor by Category',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Category Selector
                  SizedBox(
                    height: 110,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.1,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name']!;
                            });
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: _selectedCategory == category['name']
                                      ? Colors.blue[50]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedCategory == category['name']
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    category['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category['name']!,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Doctor List using DoctorCard
                  Expanded(
                    child: filteredDoctors.isEmpty
                        ? const Center(child: Text("No approved doctors yet"))
                        : ListView.builder(
                            itemCount: filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = filteredDoctors[index];
                              return DoctorCard(
                                doctor: doctor,
                                onTap: () => _handleDoctorTap(doctor),
                                onBookPressed: () =>
                                    _openAppointmentForm(doctor),
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
