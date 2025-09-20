// lib/screens/lib/screens/doctor_dashboard_lab.dart
import 'package:flutter/material.dart';
import '../../upload_document_screen.dart';
import 'doctor/Doctor Module Exports/doctor_chatlist_page.dart';

class LabDoctorDashboard extends StatelessWidget {
  const LabDoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lab Doctor Dashboard"),
        backgroundColor: const Color(0xff0064FA),
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
              context,
              icon: Icons.upload_file,
              title: "Upload Reports",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadDocumentScreen(
                      patientId: '',
                      patientName: '',
                      doctorId: '',
                    ),
                  ),
                );
              },
            ),
            // Chats
            _dashboardCard(
              context,
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
