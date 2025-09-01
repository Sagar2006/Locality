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
    try {
      // Handle potential type issues with numeric values from Firebase
      double parseRating(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }
      
      int parseRatingCount(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }
    
      return UserModel(
        uid: documentId,
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        location: map['location']?.toString() ?? '',
        profilePicUrl: map['profilePicUrl']?.toString(),
        rating: parseRating(map['rating']),
        ratingCount: parseRatingCount(map['ratingCount']),
      );
    } catch (e) {
      print('Error parsing UserModel from map: $e');
      print('Map data: $map');
      // Return a default user rather than crashing
      return UserModel(
        uid: documentId,
        name: 'Error User',
        email: '',
        phone: '',
        location: '',
      );
    }
  }
}
