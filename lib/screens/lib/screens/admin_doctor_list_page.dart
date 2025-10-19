// lib/screens/admin/admin_doctor_list.dart

import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDoctorList extends StatefulWidget {
  const AdminDoctorList({super.key});

  @override
  State<AdminDoctorList> createState() => _AdminDoctorListState();
}

class _AdminDoctorListState extends State<AdminDoctorList> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child(
    "users",
  );

  List<Doctor> _verifiedDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVerifiedDoctors();
  }

  /// Fetch only verified doctors from Firebase
  Future<void> _fetchVerifiedDoctors() async {
    final snapshot = await _database.once();
    List<Doctor> tmpDoctors = [];

    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> values =
          snapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (value['role'] == 'doctor' && value['isVerified'] == true) {
          Doctor doctor = Doctor.fromMap(value, key, id: null);
          tmpDoctors.add(doctor);
        }
      });
    }

    setState(() {
      _verifiedDoctors = tmpDoctors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verified Doctors")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verifiedDoctors.isEmpty
          ? const Center(child: Text("No verified doctors available"))
          : ListView.builder(
              itemCount: _verifiedDoctors.length,
              itemBuilder: (context, index) {
                final doc = _verifiedDoctors[index];
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
                    // ignore: unnecessary_string_interpolations
                    subtitle: Text("${doc.category}"),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
