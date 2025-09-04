import 'package:firebase_database/firebase_database.dart';
import 'package:locality/models/item_model.dart';

class SampleDataService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> addSampleItems() async {
    try {
      final items = [
        Item(
          id: 'sample-1',
          ownerId: 'sample-owner',
          name: 'MacBook Pro 16"',
          description: 'High-performance laptop perfect for creative work and development',
          category: 'Electronics',
          pricePerDay: 25.0,
          imageUrls: ['https://via.placeholder.com/300x200?text=MacBook+Pro'],
          rating: 4.8,
          ratingCount: 12,
          location: 'San Francisco, CA',
        ),
        Item(
          id: 'sample-2',
          ownerId: 'sample-owner',
          name: 'DJI Mavic Air 2',
          description: 'Professional drone for aerial photography and videography',
          category: 'Electronics',
          pricePerDay: 35.0,
          imageUrls: ['https://via.placeholder.com/300x200?text=DJI+Drone'],
          rating: 4.5,
          ratingCount: 8,
          location: 'Los Angeles, CA',
        ),
        Item(
          id: 'sample-3',
          ownerId: 'sample-owner',
          name: 'Camping Tent',
          description: '4-person waterproof camping tent, perfect for outdoor adventures',
          category: 'Sports',
          pricePerDay: 15.0,
          imageUrls: ['https://via.placeholder.com/300x200?text=Camping+Tent'],
          rating: 4.2,
          ratingCount: 15,
          location: 'Denver, CO',
        ),
        Item(
          id: 'sample-4',
          ownerId: 'sample-owner',
          name: 'Mountain Bike',
          description: 'Full suspension mountain bike for trails and off-road adventures',
          category: 'Sports',
          pricePerDay: 20.0,
          imageUrls: ['https://via.placeholder.com/300x200?text=Mountain+Bike'],
          rating: 3.8,
          ratingCount: 6,
          location: 'Boulder, CO',
        ),
        Item(
          id: 'sample-5',
          ownerId: 'sample-owner',
          name: 'Professional Camera',
          description: 'Canon EOS R5 with multiple lenses for professional photography',
          category: 'Electronics',
          pricePerDay: 45.0,
          imageUrls: ['https://via.placeholder.com/300x200?text=Canon+Camera'],
          rating: 4.9,
          ratingCount: 20,
          location: 'New York, NY',
        ),
      ];

      for (var item in items) {
        await _database.ref().child('items').child(item.id).set(item.toMap());
        print('Added sample item: ${item.name}');
      }

      print('Successfully added ${items.length} sample items to database');
    } catch (e) {
      print('Error adding sample items: $e');
    }
  }
}
