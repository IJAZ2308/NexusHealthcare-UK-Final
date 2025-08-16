// lib/models/bed_model.dart

class HospitalBed {
  final String id;
  final String name;
  final int totalBeds;
  final int availableBeds;

  HospitalBed({
    required this.id,
    required this.name,
    required this.totalBeds,
    required this.availableBeds,
  });

  factory HospitalBed.fromMap(String id, Map<String, dynamic> data) {
    return HospitalBed(
      id: id,
      name: data['name'],
      totalBeds: data['totalBeds'],
      availableBeds: data['availableBeds'],
    );
  }
}
