import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage:
              AssetImage("assets/images/doctor.png"), // placeholder
        ),
        title: Text(
          doctor.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          doctor.specialization,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
