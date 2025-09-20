import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class VerifyDoctorsScreen extends StatefulWidget {
  const VerifyDoctorsScreen({super.key});

  @override
  State<VerifyDoctorsScreen> createState() => _VerifyDoctorsScreenState();
}

class _VerifyDoctorsScreenState extends State<VerifyDoctorsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> pendingDoctors = [];

  @override
  void initState() {
    super.initState();
    _loadPendingDoctors();
  }

  Future<void> _loadPendingDoctors() async {
    final snapshot = await _dbRef
        .child("doctors")
        .orderByChild("status")
        .equalTo("pending")
        .get();

    List<Map<String, dynamic>> temp = [];
    if (snapshot.value != null) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        temp.add({
          "id": key,
          "name": "${value["firstName"]} ${value["lastName"]}",
          "email": value["email"],
          "qualification": value["qualification"],
        });
      });
    }

    if (!mounted) return;
    setState(() {
      pendingDoctors = temp;
    });
  }

  Future<void> _verifyDoctor(String id) async {
    await _dbRef.child("doctors/$id/status").set("verified");
    _loadPendingDoctors();
  }

  Future<void> _rejectDoctor(String id) async {
    await _dbRef.child("doctors/$id/status").set("rejected");
    _loadPendingDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Pending Doctors")),
      body: pendingDoctors.isEmpty
          ? const Center(child: Text("No pending doctors"))
          : ListView.builder(
              itemCount: pendingDoctors.length,
              itemBuilder: (context, index) {
                final doc = pendingDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(doc["name"]),
                    subtitle: Text(
                      "${doc["email"]}\nQualification: ${doc["qualification"]}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _verifyDoctor(doc["id"]),
                          child: const Text("Approve"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectDoctor(doc["id"]),
                          child: const Text("Reject"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
