class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String time;
  final String reason;
  final String status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.reason,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'reason': reason,
      'status': status,
    };
  }

  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      patientId: map['patientId'],
      doctorId: map['doctorId'],
      date: map['date'],
      time: map['time'],
      reason: map['reason'],
      status: map['status'],
    );
  }
}
