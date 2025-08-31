import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final String patientId;

  const ChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required String patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctorName)),
      body: Center(
        child: Text(
            'Chat with $doctorName\n(doctorId: $doctorId)\n(patientId: $patientId)'),
      ),
    );
  }
}
