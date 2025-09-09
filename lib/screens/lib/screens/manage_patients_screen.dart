// lib/screens/manage_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({super.key});

  @override
  State<ManagePatientsScreen> createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'patients',
  );

  Future<void> _updateVerification(String patientId, bool value) async {
    await _dbRef.child(patientId).update({'verified': value});
  }

  Future<void> _deletePatient(String patientId) async {
    await _dbRef.child(patientId).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Patients")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No patients found"));
          }

          final Map<dynamic, dynamic> patientsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> patients = patientsMap.entries.map((
            e,
          ) {
            final data = e.value as Map<dynamic, dynamic>;
            data['patientId'] = e.key;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final data = patients[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email']}"),
                      Text("Verified: ${data['verified']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateVerification(data['patientId'], true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateVerification(data['patientId'], false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deletePatient(data['patientId']),
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
