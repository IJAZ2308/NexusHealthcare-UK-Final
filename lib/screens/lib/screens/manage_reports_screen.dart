// lib/screens/manage_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'reports',
  );

  Future<void> _deleteReport(String reportId) async {
    await _dbRef.child(reportId).remove();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Reports")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No reports found"));
          }

          final Map<dynamic, dynamic> reportsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> reports = reportsMap.entries.map((
            e,
          ) {
            final data = e.value as Map<dynamic, dynamic>;
            data['reportId'] = e.key;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['reportName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Patient ID: ${data['patientId']}"),
                      Text("Uploaded on: ${data['uploadedOn']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                        onPressed: () => _openUrl(data['reportUrl']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deleteReport(data['reportId']),
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
