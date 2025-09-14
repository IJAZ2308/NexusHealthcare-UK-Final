import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'doctor_details_page.dart';
import 'doctor_card.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child(
    'Doctors',
  );
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  final List<Map<String, String>> specialties = [
    {"title": "General Surgery", "icon": "assets/images/surgery.png"},
    {"title": "Orthopaedics", "icon": "assets/images/ortho.png"},
    {"title": "Neurosurgery", "icon": "assets/images/neuro.png"},
    {"title": "Cardiothoracic", "icon": "assets/images/heart.png"},
    {"title": "Vascular Surgery", "icon": "assets/images/vascular.png"},
    {"title": "ENT", "icon": "assets/images/ent.png"},
    {"title": "Ophthalmology", "icon": "assets/images/eye.png"},
    {"title": "Urology", "icon": "assets/images/urology.png"},
    {"title": "Plastic Surgery", "icon": "assets/images/plastic.png"},
    {"title": "Paediatric Surgery", "icon": "assets/images/child.png"},
    {"title": "Neonatology", "icon": "assets/images/neonatal.png"},
    {
      "title": "Obstetrics & Gynaecology (O&G)",
      "icon": "assets/images/gyn.png",
    },
    {"title": "Oncology", "icon": "assets/images/onco.png"},
    {"title": "General Practice", "icon": "assets/images/gp.png"},
    {"title": "Radiology & Imaging", "icon": "assets/images/ru.png"},
    {"title": "Emergency service", "icon": "assets/images/es.png"},
    {"title": "Public Health", "icon": "assets/images/public.png"},
    {"title": "Occupational Health", "icon": "assets/images/work.png"},
    {"title": "See All", "icon": "assets/images/grid.png"},
  ];

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
        Doctor doctor = Doctor.fromMap(value, key, id: key);
        tmpDoctors.add(doctor);
      });
    }
    setState(() {
      _doctors = tmpDoctors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctors")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30.0),
                  const Text(
                    'Find your doctor,\nand book an appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Find Doctor by Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 250,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: specialties.length,
                      itemBuilder: (context, index) {
                        final spec = specialties[index];
                        return _buildCategoryCard(
                          context,
                          spec["title"]!,
                          spec["icon"]!,
                          isHighlighed: spec["title"] == "See All",
                        );
                      },
                    ),
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
                        final doctor = _doctors[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorDetailPage(doctor: doctor),
                              ),
                            );
                          },
                          child: DoctorCard(doctor: doctor),
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

Widget _buildCategoryCard(
  BuildContext context,
  String title,
  dynamic icon, {
  bool isHighlighed = false,
}) {
  return Container(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(
                icon,
                size: 40,
                color: isHighlighed ? Colors.white : const Color(0xff006AFA),
              )
            else
              Image.asset(
                icon,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.grey,
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isHighlighed ? Colors.white : const Color(0xff006AFA),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
