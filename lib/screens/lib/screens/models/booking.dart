class Booking {
  final String id; // Unique booking ID (from push().key in Realtime DB)
  final String description;
  final String date;
  final String time;
  final String status;

  Booking({
    required this.id,
    required this.description,
    required this.date,
    required this.time,
    required this.status,
  });

  /// Create Booking from Map (Realtime DB JSON + key)
  factory Booking.fromMap(Map<dynamic, dynamic> map, {required String id}) {
    return Booking(
      id: id, // comes from snapshot.key
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      status: map['status'] ?? '',
    );
  }

  /// Convert Booking to Map (for saving in Realtime DB)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}
