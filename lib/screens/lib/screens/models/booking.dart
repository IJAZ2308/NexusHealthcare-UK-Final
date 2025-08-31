class Booking {
  final String id; // Unique booking ID
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

  /// Create Booking from Map (e.g., Firestore JSON + document ID)
  factory Booking.fromMap(Map<String, dynamic> map, {required String id}) {
    return Booking(
      id: id, // comes from Firestore doc.id or manual assignment
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      status: map['status'] ?? '',
    );
  }

  /// Convert Booking to Map (for saving in Firestore/DB)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}
