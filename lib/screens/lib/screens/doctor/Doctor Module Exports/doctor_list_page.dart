import 'package:dr_shahin_uk/screens/lib/screens/doctor/Doctor%20Module%20Exports/doctor_card.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor/Doctor%20Module%20Exports/doctor_details_page.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('Doctors');
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    await _database.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      List<Doctor> tmpDoctors = [];
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          Doctor doctor = Doctor.fromMap(value, key, id: '');
          tmpDoctors.add(doctor);
        });
      }
      setState(() {
        _doctors = tmpDoctors;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30.0),
                  const Text(
                    'Find your doctor,\nand book an appointment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Find Doctor by Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCategoryCard(
                          context, 'Cardiologist', 'assets/images/heart.png'),
                      _buildCategoryCard(
                          context, 'Dentist', 'assets/images/dental.png'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCategoryCard(
                          context, 'Oncologist', 'assets/images/onco.png'),
                      _buildCategoryCard(
                          context, 'See All', 'assets/images/grid.png',
                          isHighlighed: true),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Top Doctors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'VIEW ALL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff006AFA),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorDetailPage(doctor: _doctors[index]),
                              ),
                            );
                          },
                          child: DoctorCard(doctor: _doctors[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _buildCategoryCard(BuildContext context, String title, dynamic icon,
    {bool isHighlighed = false}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.4,
    decoration: BoxDecoration(
      color: isHighlighed ? const Color(0xff006AFA) : const Color(0xffF0EFFF),
      borderRadius: BorderRadius.circular(15),
      border: isHighlighed
          ? null
          : Border.all(color: const Color(0xffC8C4FF), width: 2),
    ),
    child: Card(
      color: isHighlighed ? const Color(0xff006AFA) : const Color(0xffF0EFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(
                icon,
                size: 40,
                color: isHighlighed ? Colors.white : const Color(0xffF0EFFF),
              )
            else
              Image.asset(
                icon,
                width: 40,
                height: 40,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: isHighlighed ? Colors.white : const Color(0xff006AFA),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
