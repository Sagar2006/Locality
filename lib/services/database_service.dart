import 'package:firebase_database/firebase_database.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/models/rental_model.dart';
import 'package:locality/models/user_model.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Users
  Future<void> createUser(UserModel user) async {
    try {
      await _database.ref().child('users').child(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      throw e;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _database.ref().child('users').child(uid).get();
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.value as Map<String, dynamic>, snapshot.key!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _database.ref().child('users').child(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Items
  Future<String> createItem(Item item) async {
    try {
      final ref = _database.ref().child('items').push();
      final newItem = Item(
        id: ref.key!,
        ownerId: item.ownerId,
        name: item.name,
        description: item.description,
        category: item.category,
        price: item.price,
        imageUrls: item.imageUrls,
        location: item.location,
      );
      
      await ref.set(newItem.toMap());
      return ref.key!;
    } catch (e) {
      print('Error creating item: $e');
      throw e;
    }
  }

  Future<Item?> getItem(String itemId) async {
    try {
      final snapshot = await _database.ref().child('items').child(itemId).get();
      if (snapshot.exists) {
        return Item.fromMap(
            snapshot.value as Map<String, dynamic>, snapshot.key!);
      }
      return null;
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  Future<void> updateItem(Item item) async {
    try {
      await _database
          .ref()
          .child('items')
          .child(item.id)
          .update(item.toMap());
    } catch (e) {
      print('Error updating item: $e');
      throw e;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _database.ref().child('items').child(itemId).remove();
    } catch (e) {
      print('Error deleting item: $e');
      throw e;
    }
  }

  Future<List<Item>> getItems() async {
    try {
      final snapshot = await _database.ref().child('items').get();
      if (snapshot.exists) {
        final items = <Item>[];
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          items.add(Item.fromMap(Map<String, dynamic>.from(value), key));
        });
        return items;
      }
      return [];
    } catch (e) {
      print('Error getting items: $e');
      return [];
    }
  }

  Future<List<Item>> getItemsByOwner(String ownerId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('items')
          .orderByChild('ownerId')
          .equalTo(ownerId)
          .get();
      
      if (snapshot.exists) {
        final items = <Item>[];
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          items.add(Item.fromMap(Map<String, dynamic>.from(value), key));
        });
        return items;
      }
      return [];
    } catch (e) {
      print('Error getting items by owner: $e');
      return [];
    }
  }

  // Rental Requests
  Future<String> createRentalRequest(RentalRequest request) async {
    try {
      final ref = _database.ref().child('requests').push();
      final newRequest = RentalRequest(
        id: ref.key!,
        itemId: request.itemId,
        lenderId: request.lenderId,
        borrowerId: request.borrowerId,
        status: request.status,
        startDate: request.startDate,
        endDate: request.endDate,
        totalPrice: request.totalPrice,
      );
      
      await ref.set(newRequest.toMap());
      return ref.key!;
    } catch (e) {
      print('Error creating rental request: $e');
      throw e;
    }
  }

  Future<RentalRequest?> getRentalRequest(String requestId) async {
    try {
      final snapshot = await _database.ref().child('requests').child(requestId).get();
      if (snapshot.exists) {
        return RentalRequest.fromMap(
            snapshot.value as Map<String, dynamic>, snapshot.key!);
      }
      return null;
    } catch (e) {
      print('Error getting rental request: $e');
      return null;
    }
  }

  Future<void> updateRentalRequest(RentalRequest request) async {
    try {
      await _database
          .ref()
          .child('requests')
          .child(request.id)
          .update(request.toMap());
    } catch (e) {
      print('Error updating rental request: $e');
      throw e;
    }
  }

  Future<List<RentalRequest>> getRentalRequestsByBorrower(String borrowerId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('requests')
          .orderByChild('borrowerId')
          .equalTo(borrowerId)
          .get();
      
      if (snapshot.exists) {
        final requests = <RentalRequest>[];
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          requests.add(RentalRequest.fromMap(Map<String, dynamic>.from(value), key));
        });
        return requests;
      }
      return [];
    } catch (e) {
      print('Error getting rental requests by borrower: $e');
      return [];
    }
  }

  Future<List<RentalRequest>> getRentalRequestsByLender(String lenderId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('requests')
          .orderByChild('lenderId')
          .equalTo(lenderId)
          .get();
      
      if (snapshot.exists) {
        final requests = <RentalRequest>[];
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          requests.add(RentalRequest.fromMap(Map<String, dynamic>.from(value), key));
        });
        return requests;
      }
      return [];
    } catch (e) {
      print('Error getting rental requests by lender: $e');
      return [];
    }
  }
}
