import 'package:dr_shahin_uk/screens/lib/screens/shared_reports_screen.dart';
import 'package:dr_shahin_uk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:dr_shahin_uk/screens/upload_document_screen.dart';
import 'package:dr_shahin_uk/screens/view_documents_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/doctor_appointments_screen.dart';
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
    NotificationService.initialize(); // 👈 initialize local notifications
    NotificationService.setupFCM(); // 👈 setup FCM token & listeners
  }

  Future<void> _initDoctor() async {
    await _fetchDoctorData();
    await _fetchAppointments();
    await _fetchDoctorPatients(); // 👈 fetch patients related to this doctor
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

  // ✅ fetch appointments for this doctor
  Future<void> _fetchAppointments() async {
    setState(() => _loadingAppointments = true);
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

      for (var entry in dataMap.entries) {
        final appt = Map<String, dynamic>.from(entry.value);
        String patientName = "Unknown";

        if (appt['patientId'] != null) {
          final patientSnapshot = await _db.child(appt['patientId']).get();
          if (patientSnapshot.exists) {
            final patientData = Map<String, dynamic>.from(
              patientSnapshot.value as Map,
            );
            patientName = patientData['name'] ?? "Unknown";
          }
        }

        loadedAppointments.add({
          'id': entry.key,
          'patientId': appt['patientId'] ?? '',
          'patientName': patientName,
          'date': appt['date'] ?? '',
          'time': appt['time'] ?? '',
        });
      }
    }

    setState(() {
      _appointments = loadedAppointments;
      _loadingAppointments = false;
    });
  }

  // ✅ show only patients who have appointments with this doctor
  Future<void> _fetchDoctorPatients() async {
    final doctorId = _auth.currentUser!.uid;
    final appointmentSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .get();

    final Set<String> patientIds = {};

    if (appointmentSnapshot.exists) {
      final Map<dynamic, dynamic> apptMap =
          appointmentSnapshot.value as Map<dynamic, dynamic>;
      for (var entry in apptMap.entries) {
        final appt = Map<String, dynamic>.from(entry.value);
        if (appt['patientId'] != null) {
          patientIds.add(appt['patientId']);
        }
      }
    }

    // Now fetch patient names
    final List<Map<String, String>> loadedPatients = [];
    for (var id in patientIds) {
      final patientSnapshot = await _db.child(id).get();
      if (patientSnapshot.exists) {
        final data = Map<String, dynamic>.from(patientSnapshot.value as Map);
        loadedPatients.add({'uid': id, 'name': data['name'] ?? 'Patient'});
      }
    }

    setState(() => _patients = loadedPatients);
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Logout"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _pickPatientAndUpload() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No patients assigned yet.")),
      );
      return;
    }

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

  void _pickPatientToViewDocuments() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No patients assigned yet.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Select Patient to View Documents"),
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
                        builder: (_) => ViewDocumentsScreen(
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

  void _openSharedReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SharedReportsScreen()),
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
                    icon: Icons.folder_open,
                    title: "View Documents",
                    color: Colors.orange,
                    onTap: _pickPatientToViewDocuments,
                  ),
                  _dashboardCard(
                    icon: Icons.share,
                    title: "Shared Reports",
                    color: Colors.teal,
                    onTap: _openSharedReports,
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
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
