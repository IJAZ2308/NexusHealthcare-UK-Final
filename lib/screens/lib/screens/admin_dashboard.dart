// lib/screens/admin_dashboard.dart
import 'package:dr_shahin_uk/screens/shared/verify_pending.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // for formatting date
import 'package:url_launcher/url_launcher.dart';
import 'manage_doctors_screen.dart';
import 'manage_patients_screen.dart';
import 'manage_hospitals_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  int totalDoctors = 0;
  int totalPatients = 0;
  int totalHospitals = 0;
  int totalAppointments = 0;
  int pendingDoctors = 0;

  Map<String, dynamic> hospitals = {};
  Map<String, dynamic> doctors = {};

  List<Map<String, dynamic>> appointments = [];
  bool _isLoadingAppointments = true;

  int _selectedFilter = 0; // 0=All, 1=Upcoming, 2=Cancelled, 3=Completed
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadPendingDoctorsCount();
    _loadAppointments();
  }

  Future<void> _loadCounts() async {
    final doctorsSnap = await _dbRef.child('doctors').get();
    final patientsSnap = await _dbRef.child('patients').get();
    final hospitalsSnap = await _dbRef.child('hospitals').get();
    final appointmentsSnap = await _dbRef.child('appointments').get();

    if (!mounted) return;

    setState(() {
      totalDoctors = doctorsSnap.value != null
          ? (doctorsSnap.value as Map).length
          : 0;
      totalPatients = patientsSnap.value != null
          ? (patientsSnap.value as Map).length
          : 0;
      totalHospitals = hospitalsSnap.value != null
          ? (hospitalsSnap.value as Map).length
          : 0;
      totalAppointments = appointmentsSnap.value != null
          ? (appointmentsSnap.value as Map).length
          : 0;

      hospitals = hospitalsSnap.value != null
          ? Map<String, dynamic>.from(hospitalsSnap.value as Map)
          : {};
      doctors = doctorsSnap.value != null
          ? Map<String, dynamic>.from(doctorsSnap.value as Map)
          : {};
    });
  }

  Future<void> _loadPendingDoctorsCount() async {
    final snapshot = await _dbRef
        .child('doctors')
        .orderByChild('isVerified')
        .equalTo(false)
        .get();

    if (!mounted) return;

    setState(() {
      pendingDoctors = snapshot.value != null
          ? (snapshot.value as Map).length
          : 0;
    });
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoadingAppointments = true);
    final snapshot = await _dbRef.child('appointments').get();

    List<Map<String, dynamic>> tmp = [];
    if (snapshot.value != null) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        tmp.add({
          'id': key,
          'doctorName': value['doctorName'] ?? '',
          'patientName': value['patientName'] ?? '',
          'specialty': value['specialization'] ?? '',
          'dateTime': value['dateTime'] ?? '',
          'status': value['status'] ?? 'pending',
          'cancelReason': value['cancelReason'] ?? '',
        });
      });
    }

    if (!mounted) return;
    setState(() {
      appointments = tmp;
      _isLoadingAppointments = false;
    });
  }

  Widget _buildCountCard(String title, int count, Color color) {
    return Card(
      color: color,
      child: SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      if (!mounted) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open URL")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Apply filters
    List<Map<String, dynamic>> filteredAppointments = appointments.where((
      appt,
    ) {
      final status = (appt['status'] ?? '').toString().toLowerCase();
      final dt = DateTime.tryParse(appt['dateTime'] ?? '');

      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 1: // Upcoming
          matchesFilter =
              (status == 'pending' || status == 'confirmed') &&
              dt != null &&
              dt.isAfter(DateTime.now());
          break;
        case 2: // Cancelled
          matchesFilter = status == 'cancelled';
          break;
        case 3: // Completed
          matchesFilter = status == 'completed';
          break;
        default:
          matchesFilter = true;
      }

      bool matchesSearch =
          appt['doctorName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          appt['patientName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildCountCard("Doctors", totalDoctors, Colors.blue),
                _buildCountCard("Patients", totalPatients, Colors.green),
                _buildCountCard("Hospitals", totalHospitals, Colors.orange),
                _buildCountCard(
                  "Appointments",
                  totalAppointments,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNavigationCard("Manage Doctors", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDoctorsScreen()),
              );
            }),
            _buildNavigationCard("Manage Patients", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePatientsScreen()),
              );
            }),
            _buildNavigationCard("Manage Hospitals", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageHospitalsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Appointments", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageAppointmentsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Reports", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageReportsScreen()),
              );
            }),
            _buildNavigationCard(
              "Verify Pending Doctors ($pendingDoctors)",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyPending()),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Hospital Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hospitals.keys.length,
              itemBuilder: (context, index) {
                final hospitalId = hospitals.keys.elementAt(index);
                final data = hospitals[hospitalId];
                return Card(
                  child: ListTile(
                    title: Text(data['name']),
                    subtitle: Text("Available Beds: ${data['availableBeds']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () => _openUrl(data['website']),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Doctor License Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.keys.length,
              itemBuilder: (context, index) {
                final doctorId = doctors.keys.elementAt(index);
                final data = doctors[doctorId];
                if (data['licenseUrl'] == null || data['licenseUrl'].isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  child: ListTile(
                    title: Text(data['name']),
                    subtitle: Text("Specialty: ${data['specialty']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () => _openUrl(data['licenseUrl']),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Doctor ↔ Patient Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // 🔹 Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: "Search by doctor or patient",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 10),
            // 🔹 Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: _selectedFilter == 0,
                  onSelected: (_) => setState(() => _selectedFilter = 0),
                ),
                ChoiceChip(
                  label: const Text("Upcoming"),
                  selected: _selectedFilter == 1,
                  onSelected: (_) => setState(() => _selectedFilter = 1),
                ),
                ChoiceChip(
                  label: const Text("Cancelled"),
                  selected: _selectedFilter == 2,
                  onSelected: (_) => setState(() => _selectedFilter = 2),
                ),
                ChoiceChip(
                  label: const Text("Completed"),
                  selected: _selectedFilter == 3,
                  onSelected: (_) => setState(() => _selectedFilter = 3),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoadingAppointments
                ? const Center(child: CircularProgressIndicator())
                : filteredAppointments.isEmpty
                ? const Text("No appointments found.")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = filteredAppointments[index];
                      final dt = DateTime.tryParse(appt['dateTime'] ?? '');
                      final formatted = dt != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
                          : 'Unknown';

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${appt['doctorName']} → ${appt['patientName']}",
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Specialty: ${appt['specialty']}"),
                              Text("Date: $formatted"),
                              Text("Status: ${appt['status']}"),
                              if (appt['cancelReason'] != null &&
                                  appt['cancelReason'].toString().isNotEmpty)
                                Text(
                                  "Reason: ${appt['cancelReason']}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class VerifyPendingDoctorsPage {
  const VerifyPendingDoctorsPage();
}
