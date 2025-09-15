class Doctor {
  final String uid;
  final String category; // Specialization
  final String city;
  final String email;
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final String qualification;
  final String phoneNumber;
  final int yearsOfExperience;
  final double latitude;
  final double longitude;
  final int numberOfReviews;
  final int totalReviews;
  final bool isVerified; // ✅ New field for verification

  Doctor({
    required this.uid,
    required this.category,
    required this.city,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.qualification,
    required this.phoneNumber,
    required this.yearsOfExperience,
    required this.latitude,
    required this.longitude,
    required this.numberOfReviews,
    required this.totalReviews,
    this.isVerified = false, // default not verified
  });

  /// Factory constructor for Realtime Database snapshot
  factory Doctor.fromMap(Map<dynamic, dynamic> map, String uid, {required id}) {
    return Doctor(
      uid: uid,
      category: map['category'] ?? '',
      city: map['city'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      qualification: map['qualification'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      yearsOfExperience:
          int.tryParse(map['yearsOfExperience']?.toString() ?? '0') ?? 0,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      numberOfReviews: map['numberOfReviews'] ?? 0,
      totalReviews: map['totalReviews'] ?? 0,
      isVerified: map['isVerified'] ?? false, // ✅ read verification status
    );
  }

  /// Convert to Map for saving in Realtime DB
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'category': category,
      'city': city,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'qualification': qualification,
      'phoneNumber': phoneNumber,
      'yearsOfExperience': yearsOfExperience,
      'latitude': latitude,
      'longitude': longitude,
      'numberOfReviews': numberOfReviews,
      'totalReviews': totalReviews,
      'isVerified': isVerified, // ✅ save verification status
    };
  }

  /// Full name getter
  String get name => '$firstName $lastName';

  /// Specialization alias
  String get specialization => category;

  /// ✅ Get a message about verification
  String get verificationMessage =>
      isVerified ? "You are verified ✅" : "Not verified ❌";
}
