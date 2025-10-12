// lib/screens/patient_dashboard.dart

import 'package:dr_shahin_uk/screens/lib/screens/patient/appointment_list_page.dart';
import 'package:dr_shahin_uk/screens/lib/screens/shared_reports_screen.dart';
import 'package:dr_shahin_uk/screens/view_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your screens
import 'bed_list_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/Doctor%20Module%20Exports/doctor_list_page.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/chat/chat_screen.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        backgroundColor: const Color(0xff0064FA), // ✅ for consistency
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
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
              "Welcome, Patient 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Quick access to your health services below:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Dashboard Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _dashboardCard(
                  context,
                  icon: Icons.local_hospital,
                  title: "Doctors",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DoctorListPage()),
                    );
                  },
                ),
                _dashboardCard(
                  context,
                  icon: Icons.event,
                  title: "Appointments",
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentListPage(),
                      ),
                    );
                  },
                ),
                _dashboardCard(
                  context,
                  icon: Icons.bed,
                  title: "Bed Availability & Appointment booking",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BedListScreen()),
                    );
                  },
                ),
                _dashboardCard(
                  context,
                  icon: Icons.chat,
                  title: "Chat",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatScreen(
                          doctorId: '',
                          doctorName: '',
                          patientId: '',
                          patientName: '',
                        ),
                      ),
                    );
                  },
                ),
                _dashboardCard(
                  context,
                  icon: Icons.upload_file,
                  title: "View Reports",
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewDocumentsScreen(
                          patientId: '',
                          patientName: '',
                          doctorName: '',
                          doctorId: '',
                        ),
                      ),
                    );
                  },
                ),
                _dashboardCard(
                  context,
                  icon: Icons.folder_shared,
                  title: "Shared Reports",
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SharedReportsScreen(),
                      ),
                    );
                  },
                ),
              ],
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
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
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
