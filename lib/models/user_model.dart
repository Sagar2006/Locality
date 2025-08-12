class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String? profilePicUrl;
  final double rating;
  final int ratingCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.profilePicUrl,
    this.rating = 0,
    this.ratingCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'profilePicUrl': profilePicUrl,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }
}
