import 'package:flutter/material.dart';

class AppointmentListPage extends StatelessWidget {
  const AppointmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for appointments
    final List<Map<String, String>> appointments = [
      {
        "doctor": "Dr. John Doe",
        "specialization": "Cardiologist",
        "time": "10:30 AM",
      },
      {
        "doctor": "Dr. Sarah Lee",
        "specialization": "Neurologist",
        "time": "02:00 PM",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.teal),
              title: Text(appt["doctor"]!),
              subtitle: Text("${appt["specialization"]} • ${appt["time"]}"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}
