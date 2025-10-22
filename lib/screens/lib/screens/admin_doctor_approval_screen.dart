import 'package:dr_shahin_uk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// <-- Import your NotificationService

class AdminDoctorApprovalScreen extends StatefulWidget {
  const AdminDoctorApprovalScreen({super.key});

  @override
  State<AdminDoctorApprovalScreen> createState() =>
      _AdminDoctorApprovalScreenState();
}

class _AdminDoctorApprovalScreenState extends State<AdminDoctorApprovalScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'doctors',
  );
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> pendingDoctors = [];
  List<Map<String, dynamic>> approvedDoctors = [];
  List<Map<String, dynamic>> rejectedDoctors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final snapshot = await _dbRef.get();
    final data = snapshot.value as Map<dynamic, dynamic>?;

    List<Map<String, dynamic>> tempPending = [];
    List<Map<String, dynamic>> tempApproved = [];
    List<Map<String, dynamic>> tempRejected = [];

    if (data != null) {
      data.forEach((key, value) {
        if (value is Map) {
          final role = value['role'] ?? '';
          final status = value['status'] ?? '';
          if (role == 'labDoctor' || role == 'consultingDoctor') {
            final doctor = {
              'id': key,
              'name': "${value['firstName'] ?? ''} ${value['lastName'] ?? ''}"
                  .trim(),
              'email': value['email'] ?? '',
              'license': value['license'] ?? '',
              'role': role,
              'status': status,
              'fcmToken': value['fcmToken'] ?? '',
            };
            if (status == 'pending') tempPending.add(doctor);
            if (status == 'approved') tempApproved.add(doctor);
            if (status == 'rejected') tempRejected.add(doctor);
          }
        }
      });
    }

    setState(() {
      pendingDoctors = tempPending;
      approvedDoctors = tempApproved;
      rejectedDoctors = tempRejected;
      _isLoading = false;
    });
  }

  /// Update doctor status and send FCM directly
  Future<void> _updateDoctorStatus(
    String doctorId,
    String status,
    bool isVerified,
  ) async {
    await _dbRef.child(doctorId).update({
      'status': status,
      'isVerified': isVerified,
    });

    await _sendNotification(doctorId, status);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doctor marked as $status'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            _dbRef.child(doctorId).update({
              'status': 'pending',
              'isVerified': false,
            });
          },
        ),
      ),
    );

    _loadDoctors();
  }

  /// 🔔 Send notification directly using NotificationService
  Future<void> _sendNotification(String doctorId, String status) async {
    final snapshot = await _dbRef.child(doctorId).get();
    final doctorData = Map<String, dynamic>.from(snapshot.value as Map);
    final name =
        "${doctorData['firstName'] ?? ''} ${doctorData['lastName'] ?? ''}"
            .trim();
    final token = doctorData['fcmToken'] ?? '';

    if (token.isNotEmpty) {
      await NotificationService.sendPushNotification(
        fcmToken: token,
        title: 'Doctor Account $status',
        body: 'Hello $name, your account has been $status by the admin.',
      );
    }
  }

  void _showActionDialog(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Manage ${doctor['name']}"),
          content: const Text("Choose an action for this doctor:"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateDoctorStatus(doctor['id'], 'approved', true);
              },
              child: const Text(
                "Approve",
                style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateDoctorStatus(doctor['id'], 'rejected', false);
              },
              child: const Text("Reject", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final status = doctor['status'] ?? 'pending';
    final badgeColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.orange;
    final badgeText = status[0].toUpperCase() + status.substring(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          doctor['name'].isEmpty ? 'Unknown Doctor' : doctor['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${doctor['email']}"),
            Text("Role: ${doctor['role']}"),
            Text("License: ${doctor['license']}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: badgeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor),
          ),
          child: Text(
            badgeText,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => _showActionDialog(doctor),
      ),
    );
  }

  Widget _buildDoctorList(List<Map<String, dynamic>> list) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return const Center(child: Text("No doctors found."));

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) => _buildDoctorCard(list[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Verification Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorList(pendingDoctors),
          _buildDoctorList(approvedDoctors),
          _buildDoctorList(rejectedDoctors),
        ],
      ),
    );
  }
}
