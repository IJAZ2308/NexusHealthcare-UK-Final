// lib/screens/doctor/patient_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientReportsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;

  const PatientReportsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Map<String, dynamic> _reports = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final snapshot = await _db
        .child('patients/${widget.patientId}/reports')
        .get();
    if (snapshot.exists && snapshot.value != null) {
      if (!mounted) return;
      setState(() {
        _reports = Map<String, dynamic>.from(snapshot.value as Map);
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _reports = {};
        _loading = false;
      });
    }
  }

  Future<void> _shareReport(String reportId, String reportUrl) async {
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Notes & Share"),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(hintText: "Enter your notes"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final timestamp = DateTime.now().toIso8601String();
              await _db
                  .child('patients/${widget.patientId}/sharedReports')
                  .push()
                  .set({
                    'reportUrl': reportUrl,
                    'doctorNotes': notesController.text.trim(),
                    'sharedBy': widget.doctorId,
                    'timestamp': timestamp,
                  });
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report shared with patient")),
              );
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reports: ${widget.patientName}")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(child: Text("No reports found"))
          : ListView(
              children: _reports.entries.map((entry) {
                final report = Map<String, dynamic>.from(entry.value);
                return Card(
                  child: ListTile(
                    title: Text(report['type'] ?? 'Report'),
                    subtitle: Text("Uploaded by: ${report['uploadedBy']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            final url = report['reportUrl'];
                            if (url != null &&
                                await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () =>
                              _shareReport(entry.key, report['reportUrl']),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
