// lib/screens/doctor_dashboard_consulting.dart
import 'package:dr_shahin_uk/screens/lib/screens/doctor/doctor_appointments_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/patient_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../upload_document_screen.dart';

import 'doctor/Doctor Module Exports/doctor_chatlist_page.dart';

class ConsultingDoctorDashboard extends StatefulWidget {
  const ConsultingDoctorDashboard({super.key});

  @override
  State<ConsultingDoctorDashboard> createState() =>
      _ConsultingDoctorDashboardState();
}

class _ConsultingDoctorDashboardState extends State<ConsultingDoctorDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  String _doctorName = "Consulting Doctor";
  List<Map<String, String>> _patients = [];
  List<Map<String, String>> _appointments = [];
  bool _loadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _initDoctor();
  }

  Future<void> _initDoctor() async {
    await _fetchDoctorData();
    await _fetchPatients();
    await _fetchAppointments();
  }

  Future<void> _fetchDoctorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _db.child(user.uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _doctorName = data['name'] ?? "Consulting Doctor";
        });
      }
    }
  }

  Future<void> _fetchPatients() async {
    final snapshot = await _db.orderByChild('role').equalTo('patient').get();
    final List<Map<String, String>> loadedPatients = [];
    if (snapshot.exists) {
      final Map<dynamic, dynamic> patientsMap =
          snapshot.value as Map<dynamic, dynamic>;
      patientsMap.forEach((key, value) {
        loadedPatients.add({'uid': key, 'name': value['name'] ?? 'Patient'});
      });
    }
    setState(() => _patients = loadedPatients);
  }

  Future<void> _fetchAppointments() async {
    final doctorId = _auth.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .get();

    final List<Map<String, String>> loadedAppointments = [];
    if (snapshot.exists) {
      final Map<dynamic, dynamic> dataMap =
          snapshot.value as Map<dynamic, dynamic>;
      dataMap.forEach((key, value) {
        loadedAppointments.add({
          'id': key,
          'patientId': value['patientId'] ?? '',
          'patientName': value['patientName'] ?? 'Patient',
          'date': value['date'] ?? '',
          'time': value['time'] ?? '',
        });
      });
    }
    setState(() {
      _appointments = loadedAppointments;
      _loadingAppointments = false;
    });
  }

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _pickPatientAndUpload() {
    if (_patients.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Select Patient to Upload Document"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return ListTile(
                  title: Text(patient['name']!),
                  onTap: () {
                    Navigator.pop(context);
                    final doctorId = _auth.currentUser!.uid;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadDocumentScreen(
                          patientId: patient['uid']!,
                          patientName: patient['name']!,
                          doctorId: doctorId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _pickPatientToViewReports() {
    if (_patients.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Select Patient to View Reports"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return ListTile(
                  title: Text(patient['name']!),
                  onTap: () {
                    Navigator.pop(context);
                    final doctorId = _auth.currentUser!.uid;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientReportsScreen(
                          patientId: patient['uid']!,
                          patientName: patient['name']!,
                          doctorId: doctorId,
                          doctorName: _doctorName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Consulting Doctor Dashboard - $_doctorName"),
        backgroundColor: const Color(0xff0064FA),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _dashboardCard(
                    icon: Icons.event,
                    title: "Appointments",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorAppointmentListPage(),
                        ),
                      );
                    },
                  ),
                  _dashboardCard(
                    icon: Icons.upload_file,
                    title: "Upload Reports",
                    color: Colors.red,
                    onTap: _pickPatientAndUpload,
                  ),
                  _dashboardCard(
                    icon: Icons.folder_shared,
                    title: "View Reports",
                    color: Colors.purple,
                    onTap: _pickPatientToViewReports,
                  ),
                  _dashboardCard(
                    icon: Icons.chat,
                    title: "Chats",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorChatlistPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Upcoming Appointments:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              _loadingAppointments
                  ? const Center(child: CircularProgressIndicator())
                  : _appointments.isEmpty
                  ? const Text("No upcoming appointments")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appt = _appointments[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(appt['patientName']!),
                            subtitle: Text(
                              "${appt['date']} at ${appt['time']}",
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
