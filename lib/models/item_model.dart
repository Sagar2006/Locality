enum ItemStatus { available, rented, unavailable }
enum RentalStatus { pending, accepted, declined, completed, canceled }


class Item {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final double? pricePerDay;
  final double? pricePerHour;
  final List<String> imageUrls;
  final ItemStatus status;
  final double rating;
  final int ratingCount;
  final String location;

  Item({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    this.pricePerDay,
    this.pricePerHour,
    required this.imageUrls,
    this.status = ItemStatus.available,
    this.rating = 0,
    this.ratingCount = 0,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'pricePerDay': pricePerDay,
      'pricePerHour': pricePerHour,
      'imageUrls': imageUrls,
      'status': status.toString().split('.').last,
      'rating': rating,
      'ratingCount': ratingCount,
      'location': location,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, String documentId) {
    return Item(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      pricePerDay: map['pricePerDay'] != null ? (map['pricePerDay'] as num).toDouble() : null,
      pricePerHour: map['pricePerHour'] != null ? (map['pricePerHour'] as num).toDouble() : null,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ItemStatus.available,
      ),
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      location: map['location'] ?? '',
    );
  }
}
