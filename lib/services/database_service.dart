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
      print('DatabaseService: Getting user with uid: $uid');
      final ref = _database.ref().child('users').child(uid);
      print('DatabaseService: Ref path: ${ref.path}');
      
      final snapshot = await ref.get();
      print('DatabaseService: Snapshot exists: ${snapshot.exists}');
      
      if (snapshot.exists) {
        final raw = snapshot.value;
        print('DatabaseService: Raw data type: ${raw.runtimeType}');
        
        // Improved handling of Firebase Realtime DB data types
        Map<String, dynamic> data;
        if (raw is Map<dynamic, dynamic>) {
          data = Map<String, dynamic>.from(raw);
        } else if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        } else {
          print('DatabaseService: Unexpected data type: ${raw.runtimeType}');
          return null;
        }
        
        print('DatabaseService: Converted data: $data');
        return UserModel.fromMap(data, snapshot.key!);
      } else {
        print('DatabaseService: No user data found at path ${ref.path}');
      }
      return null;
    } catch (e) {
      print('DatabaseService: Error getting user: $e');
      print('DatabaseService: Stack trace: ${StackTrace.current}');
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
        pricePerDay: item.pricePerDay,
        pricePerHour: item.pricePerHour,
        imageUrls: item.imageUrls,
        location: item.location,
        rating: item.rating,
        ratingCount: item.ratingCount,
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
      final ref = _database.ref().child('items').child(itemId);
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw as Map);
          return Item.fromMap(data, snapshot.key!);
        } else {
          print('getItem($itemId): Unexpected data type: ${raw.runtimeType}');
        }
      } else {
        print('getItem($itemId): No snapshot at path ${ref.path}');
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
      print('Creating rental request: ${request.toMap()}');
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
      
      print('Saving request with ID: ${ref.key!}');
      await ref.set(newRequest.toMap());
      print('Request saved successfully');
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
      print('Querying requests for borrower: $borrowerId');
      final snapshot = await _database
          .ref()
          .child('requests')
          .get();
      
      print('Snapshot exists: ${snapshot.exists}');
      if (snapshot.exists) {
        final requests = <RentalRequest>[];
        final map = snapshot.value as Map<dynamic, dynamic>?;
        if (map != null) {
          print('Raw data: $map');
          map.forEach((key, value) {
            final requestData = Map<String, dynamic>.from(value as Map);
            print('Processing request with key: $key, borrowerId in data: ${requestData['borrowerId']}, looking for: $borrowerId');
            if (requestData['borrowerId'] == borrowerId) {
              try {
                requests.add(RentalRequest.fromMap(requestData, key.toString()));
                print('Added request: $key');
              } catch (e) {
                print('Error parsing request $key: $e');
              }
            }
          });
        }
        print('Found ${requests.length} requests for borrower');
        return requests;
      }
      print('No requests found in database');
      return [];
    } catch (e) {
      print('Error getting rental requests by borrower: $e');
      return [];
    }
  }

  Future<List<RentalRequest>> getRentalRequestsByLender(String lenderId) async {
    try {
      print('Querying requests for lender: $lenderId');
      final snapshot = await _database
          .ref()
          .child('requests')
          .get();
      
      if (snapshot.exists) {
        final requests = <RentalRequest>[];
        final map = snapshot.value as Map<dynamic, dynamic>?;
        if (map != null) {
          map.forEach((key, value) {
            final requestData = Map<String, dynamic>.from(value as Map);
            print('Processing request with key: $key, lenderId in data: ${requestData['lenderId']}, looking for: $lenderId');
            if (requestData['lenderId'] == lenderId) {
              try {
                requests.add(RentalRequest.fromMap(requestData, key.toString()));
                print('Added request: $key');
              } catch (e) {
                print('Error parsing request $key: $e');
              }
            }
          });
        }
        print('Found ${requests.length} requests for lender');
        return requests;
      }
      return [];
    } catch (e) {
      print('Error getting rental requests by lender: $e');
      return [];
    }
  }

  Future<bool> hasPendingRequestForItem(String borrowerId, String itemId) async {
    try {
      print('Checking pending request for borrower: $borrowerId, item: $itemId');
      final snapshot = await _database
          .ref()
          .child('requests')
          .get();
      
      if (snapshot.exists) {
        final map = snapshot.value as Map<dynamic, dynamic>?;
        if (map != null) {
          for (final entry in map.entries) {
            final requestData = Map<String, dynamic>.from(entry.value as Map);
            if (requestData['borrowerId'] == borrowerId && 
                requestData['itemId'] == itemId && 
                requestData['status'] == 'pending') {
              print('Found pending request: ${entry.key}');
              return true;
            }
          }
        }
      }
      print('No pending request found');
      return false;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }
}
