class Appointment {
  final String id; // Firebase document ID / key
  final String patientId; // Reference to patient UID
  final String doctorId; // Reference to doctor UID
  final DateTime dateTime; // Combined date & time
  final String reason; // Reason for appointment
  final String status; // pending / approved / rejected / completed

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
      'dateTime': dateTime.millisecondsSinceEpoch, // Store as timestamp
      'reason': reason,
      'status': status,
    };
  }

  /// Factory constructor from Firebase snapshot
  factory Appointment.fromMap(String id, Map<dynamic, dynamic> map) {
    return Appointment(
      id: id,
      patientId: map['patientId']?.toString() ?? '',
      doctorId: map['doctorId']?.toString() ?? '',
      dateTime: map['dateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateTime'])
          : DateTime.now(),
      reason: map['reason']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
    );
  }

  /// Create an Appointment from JSON
  factory Appointment.fromJson(Map<String, dynamic> json, String id) {
    return Appointment(
      id: id,
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  /// Convert Appointment to JSON
  Map<String, dynamic> toJson() => toMap();
}
