// lib/screens/admin/admin_doctor_approval_page.dart

import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDoctorApprovalPage extends StatefulWidget {
  const AdminDoctorApprovalPage({super.key});

  @override
  State<AdminDoctorApprovalPage> createState() =>
      _AdminDoctorApprovalPageState();
}

class _AdminDoctorApprovalPageState extends State<AdminDoctorApprovalPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child(
    "users",
  );

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;

  String _filterCategory = "All"; // Consulting, Lab, All

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final snapshot = await _database.once();
    List<Doctor> tmpDoctors = [];
    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> values =
          snapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (value['role'] == 'doctor') {
          Doctor doctor = Doctor.fromMap(value, key, id: null);
          tmpDoctors.add(doctor);
        }
      });
    }
    setState(() {
      _doctors = tmpDoctors;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_filterCategory == "All") {
      _filteredDoctors = _doctors;
    } else {
      _filteredDoctors = _doctors
          .where((doc) => doc.category == _filterCategory)
          .toList();
    }
  }

  Future<void> _approveDoctor(String uid) async {
    await _database.child(uid).update({
      "isVerified": true,
      "status": "approved",
    });
    _fetchDoctors();
  }

  Future<void> _rejectDoctor(String uid) async {
    await _database.child(uid).update({
      "isVerified": false,
      "status": "rejected",
    });
    _fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin – Approve Doctors"),
        actions: [
          DropdownButton<String>(
            value: _filterCategory,
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(
                value: "Consulting Doctor",
                child: Text("Consulting"),
              ),
              DropdownMenuItem(value: "Lab Doctor", child: Text("Lab")),
            ],
            onChanged: (value) {
              setState(() {
                _filterCategory = value!;
                _applyFilter();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDoctors.isEmpty
          ? const Center(child: Text("No doctors available"))
          : ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doc = _filteredDoctors[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: doc.profileImageUrl.isNotEmpty
                          ? NetworkImage(doc.profileImageUrl)
                          : null,
                      child: doc.profileImageUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text("${doc.firstName} ${doc.lastName}"),
                    subtitle: Text(
                      "${doc.category} • Status: ${doc.isVerified ? "Approved" : doc.status}",
                    ),
                    trailing: doc.isVerified
                        ? const Text(
                            "Approved ✅",
                            style: TextStyle(color: Colors.green),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _approveDoctor(doc.uid),
                                child: const Text("Approve"),
                              ),
                              TextButton(
                                onPressed: () => _rejectDoctor(doc.uid),
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(color: Colors.red),
                                ),
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
