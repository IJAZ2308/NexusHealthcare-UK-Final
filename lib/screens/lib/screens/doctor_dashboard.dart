// lib/screens/doctor_dashboard.dart

import 'package:dr_shahin_uk/screens/lib/screens/doctor/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'update_beds_screen.dart';
import 'package:dr_shahin_uk/screens/upload_document_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/doctor_appointments_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _bedsRef = FirebaseDatabase.instance.ref().child(
    'beds',
  );

  List<Map<String, String>> _patients = [];
  int _totalBeds = 0;
  int _availableBeds = 0;
  bool _bedsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _listenBeds();
  }

  /// Listen for bed availability changes
  void _listenBeds() {
    _bedsRef.onValue.listen((event) {
      if (mounted) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _totalBeds = data['totalBeds'] ?? 0;
            _availableBeds = data['availableBeds'] ?? 0;
            _bedsLoading = false;
          });
        } else {
          setState(() {
            _totalBeds = 0;
            _availableBeds = 0;
            _bedsLoading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchPatients() async {
    final snapshot = await _db.orderByChild('role').equalTo('patient').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> patientsMap =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, String>> loadedPatients = [];
      patientsMap.forEach((key, value) {
        loadedPatients.add({'uid': key, 'name': value['name'] ?? 'Patient'});
      });

      setState(() {
        _patients = loadedPatients;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = _auth.currentUser!.uid;
    final doctorName = "Dr. John Doe"; // Replace with dynamic doctor name

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Doctor 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Manage your services below:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // Appointments card -> navigates to DoctorAppointmentsScreen
                _dashboardCard(
                  context,
                  icon: Icons.event,
                  title: "Appointments",
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorAppointmentsScreen(),
                      ),
                    );
                  },
                ),

                // Upload Reports card
                _dashboardCard(
                  context,
                  icon: Icons.upload_file,
                  title: "Upload Reports",
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadDocumentScreen(),
                      ),
                    );
                  },
                ),

                // Update Bed Availability card with live info
                _dashboardCard(
                  context,
                  icon: Icons.bed,
                  title: _bedsLoading
                      ? "Loading Beds..."
                      : "Beds: $_availableBeds / $_totalBeds",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdateBedsScreen(),
                      ),
                    );
                  },
                ),

                // Chat with first patient (if exists)
                if (_patients.isNotEmpty)
                  _dashboardCard(
                    context,
                    icon: Icons.chat,
                    title: "Chat with ${_patients[0]['name']}",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            doctorId: doctorId,
                            doctorName: doctorName,
                            patientId: _patients[0]['uid']!,
                            patientName: _patients[0]['name']!,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 20),
            // Optional: List all patients for chat
            const Text(
              "All Patients:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(patient['name']!),
                    trailing: Icon(Icons.chat, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            doctorId: doctorId,
                            doctorName: doctorName,
                            patientId: patient['uid']!,
                            patientName: patient['name']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
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
