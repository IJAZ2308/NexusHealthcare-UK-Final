class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime dateTime; // Combined date & time
  final String reason;
  final String status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.reason,
    this.status = 'pending',
  });

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'reason': reason,
      'status': status,
    };
  }

  /// Factory constructor from Firebase snapshot
  factory Appointment.fromMap(String id, Map<dynamic, dynamic> map) {
    return Appointment(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      dateTime: map['dateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateTime'])
          : DateTime.now(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
