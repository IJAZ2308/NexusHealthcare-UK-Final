import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: doctor.profileImageUrl.isNotEmpty
              ? NetworkImage(doctor.profileImageUrl)
              : const AssetImage("assets/images/doctor.png") as ImageProvider,
        ),
        title: Text(
          "${doctor.firstName} ${doctor.lastName}", // ✅ replaced doctor.name
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "${doctor.category} • ${doctor.workingAt}", // ✅ replaced doctor.specialization
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
