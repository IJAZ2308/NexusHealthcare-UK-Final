import 'package:dr_shahin_uk/screens/lib/screens/patlabappointmentpage.dart';
import 'package:dr_shahin_uk/screens/upload_document_screen.dart';
import 'package:dr_shahin_uk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'doctor/Doctor Module Exports/doctor_chatlist_page.dart';

class LabDoctorDashboard extends StatefulWidget {
  const LabDoctorDashboard({super.key});

  @override
  State<LabDoctorDashboard> createState() => _LabDoctorDashboardState();
}

class _LabDoctorDashboardState extends State<LabDoctorDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  String _doctorName = "Lab Doctor";
  List<Map<String, String>> _patients = [];
  Map<String, List<Map<String, String>>> _patientReports = {};
  List<Map<String, String>> _appointments = [];
  bool _loadingPatients = true;
  bool _loadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
    _fetchAppointments().then((_) => _fetchPatients());

    // Initialize notifications
    NotificationService.initialize(); // 👈 local notifications
    NotificationService.setupFCM(); // 👈 FCM token & listeners
  }

  Future<void> _fetchDoctorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _db.child(user.uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _doctorName = data['name'] ?? "Lab Doctor";
        });
      }
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() => _loadingAppointments = true);
    final doctorId = _auth.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('appointments')
        .orderByChild('labDoctorId')
        .equalTo(doctorId)
        .get();

    final List<Map<String, String>> loadedAppointments = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        loadedAppointments.add({
          "id": key,
          "date": value['date'] ?? '',
          "time": value['time'] ?? '',
          "patientId": value['patientId'] ?? '',
          "status": value['status'] ?? '',
          "requestingDoctorId": value['doctorId'] ?? '',
        });
      });
    }

    setState(() {
      _appointments = loadedAppointments;
      _loadingAppointments = false;
    });
  }

  Future<void> _fetchPatients() async {
    setState(() => _loadingPatients = true);

    final List<Map<String, String>> loadedPatients = [];
    final Map<String, List<Map<String, String>>> loadedReports = {};

    for (var appt in _appointments) {
      final pid = appt['patientId']!;
      if (!loadedPatients.any((p) => p['uid'] == pid)) {
        final patientSnapshot = await _db.child(pid).get();
        if (patientSnapshot.exists) {
          final pData = Map<String, dynamic>.from(patientSnapshot.value as Map);
          loadedPatients.add({'uid': pid, 'name': pData['name'] ?? 'Patient'});

          // Fetch patient reports
          final patientReports = <Map<String, String>>[];
          if (pData['reports'] != null) {
            final Map<dynamic, dynamic> reportsMap = Map<String, dynamic>.from(
              pData['reports'],
            );
            reportsMap.forEach((key, report) {
              patientReports.add({
                'name': report['reportName'] ?? 'Report',
                'url': report['reportUrl'] ?? '',
                'doctorId': report['doctorId'] ?? '',
              });
            });
          }
          loadedReports[pid] = patientReports;
        }
      }
    }

    setState(() {
      _patients = loadedPatients;
      _patientReports = loadedReports;
      _loadingPatients = false;
    });
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _pickPatientAndUpload() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No patients with appointments assigned."),
        ),
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
                  subtitle:
                      _patientReports[patient['uid']!]?.isNotEmpty ?? false
                      ? Text(
                          "Reports: ${_patientReports[patient['uid']!]?.length ?? 0}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    final labDoctorId = _auth.currentUser!.uid;

                    final appt = _appointments.firstWhere(
                      (a) => a['patientId'] == patient['uid'],
                    );
                    final requestingDoctorId =
                        appt['requestingDoctorId'] ?? labDoctorId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadDocumentScreen(
                          patientId: patient['uid']!,
                          patientName: patient['name']!,
                          doctorId: requestingDoctorId,
                        ),
                      ),
                    ).then((_) => _fetchPatients());
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _viewAppointments() {
    if (_appointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No appointments assigned yet.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatLabAppointment()), // ✅ Updated
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lab Doctor Dashboard - $_doctorName"),
        backgroundColor: const Color(0xff0064FA),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: (_loadingPatients || _loadingAppointments)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _dashboardCard(
                    icon: Icons.upload_file,
                    title: "Upload Reports",
                    color: Colors.red,
                    badgeCount: _patients.length,
                    onTap: _pickPatientAndUpload,
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
                  _dashboardCard(
                    icon: Icons.event,
                    title: "Lab Appointments",
                    color: Colors.orange,
                    badgeCount: _appointments.length,
                    onTap: _viewAppointments,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
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
          if (badgeCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
