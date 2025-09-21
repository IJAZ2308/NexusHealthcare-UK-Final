// lib/screens/doctor_dashboard_lab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../upload_document_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
    _fetchPatients();
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

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _pickPatientAndUpload() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No patients available")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lab Doctor Dashboard - $_doctorName"),
        backgroundColor: const Color(0xff0064FA),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Upload Reports
            _dashboardCard(
              icon: Icons.upload_file,
              title: "Upload Reports",
              color: Colors.red,
              onTap: _pickPatientAndUpload,
            ),
            // Chats
            _dashboardCard(
              icon: Icons.chat,
              title: "Chats",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorChatlistPage()),
                );
              },
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
