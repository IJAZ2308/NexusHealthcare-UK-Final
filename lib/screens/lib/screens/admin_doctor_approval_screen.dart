import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDoctorApprovalScreen extends StatefulWidget {
  const AdminDoctorApprovalScreen({super.key});

  @override
  State<AdminDoctorApprovalScreen> createState() =>
      _AdminDoctorApprovalScreenState();
}

class _AdminDoctorApprovalScreenState extends State<AdminDoctorApprovalScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> pendingDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingDoctors();
  }

  Future<void> _loadPendingDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _dbRef
          .child('doctors')
          .orderByChild('status')
          .equalTo('pending')
          .get();

      if (!mounted) return;

      List<Map<String, dynamic>> tmp = [];
      if (snapshot.value != null) {
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          tmp.add({
            'id': key,
            'name': value['name'] ?? '',
            'email': value['email'] ?? '',
            'license': value['license'] ?? '',
          });
        });
      }

      setState(() {
        pendingDoctors = tmp;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading pending doctors: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveDoctor(String doctorId) async {
    try {
      await _dbRef.child('doctors/$doctorId').update({'status': 'approved'});

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doctor approved')));

      _loadPendingDoctors(); // Refresh list
    } catch (e) {
      debugPrint("Error approving doctor: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Approval failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Doctors")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pendingDoctors.length,
              itemBuilder: (context, index) {
                final doctor = pendingDoctors[index];
                return Card(
                  child: ListTile(
                    title: Text(doctor['name']),
                    subtitle: Text(doctor['email']),
                    trailing: ElevatedButton(
                      onPressed: () => _approveDoctor(doctor['id']),
                      child: const Text("Approve"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
