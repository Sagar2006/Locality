import 'package:firebase_database/firebase_database.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/models/rental_model.dart';
import 'package:locality/models/user_model.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Users
  Future<void> createUser(UserModel user) async {
    try {
      print('DatabaseService: Creating user with UID: ${user.uid}');
      print('DatabaseService: User data: ${user.toMap()}');
      
      final ref = _database.ref().child('users').child(user.uid);
      await ref.set(user.toMap());
      
      print('DatabaseService: User created successfully');
      
      // Verify the user was created
      final verification = await ref.get();
      if (verification.exists) {
        print('DatabaseService: User verification successful');
      } else {
        print('DatabaseService: WARNING - User not found after creation!');
      }
    } catch (e) {
      print('DatabaseService: Error creating user: $e');
      print('DatabaseService: Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      print('DatabaseService.getUser: Fetching user $uid');
      final ref = _database.ref().child('users').child(uid);
      final snapshot = await ref.get();
      print('DatabaseService.getUser: Snapshot exists: ${snapshot.exists}');
      
      if (snapshot.exists) {
        final raw = snapshot.value;
        print('DatabaseService.getUser: Raw data type: ${raw.runtimeType}');
        print('DatabaseService.getUser: Raw data: $raw');
        
        // Realtime DB often returns Map<dynamic, dynamic>
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw as Map);
          print('DatabaseService.getUser: Converted data: $data');
          final user = UserModel.fromMap(data, uid); // Use uid instead of snapshot.key
          print('DatabaseService.getUser: Successfully created user: ${user.name}');
          return user;
        } else {
          print('getUser($uid): Unexpected data type: ${raw.runtimeType}');
        }
      } else {
        print('getUser($uid): No data found at path ${ref.path}');
      }
      return null;
    } catch (e) {
      print('Error getting user $uid: $e');
      print('Stack trace: ${StackTrace.current}');
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
      print('DatabaseService.getItem: Fetching item $itemId');
      final ref = _database.ref().child('items').child(itemId);
      final snapshot = await ref.get();
      print('DatabaseService.getItem: Snapshot exists: ${snapshot.exists}');
      
      if (snapshot.exists) {
        final raw = snapshot.value;
        print('DatabaseService.getItem: Raw data type: ${raw.runtimeType}');
        print('DatabaseService.getItem: Raw data: $raw');
        
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw as Map);
          print('DatabaseService.getItem: Converted data: $data');
          final item = Item.fromMap(data, itemId); // Use itemId instead of snapshot.key
          print('DatabaseService.getItem: Successfully created item: ${item.name}');
          return item;
        } else {
          print('getItem($itemId): Unexpected data type: ${raw.runtimeType}');
        }
      } else {
        print('getItem($itemId): No data found at path ${ref.path}');
      }
      return null;
    } catch (e) {
      print('Error getting item $itemId: $e');
      print('Stack trace: ${StackTrace.current}');
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

  // Debug method to check database connectivity and structure
  Future<void> debugDatabaseStructure() async {
    try {
      print('=== DATABASE STRUCTURE DEBUG ===');
      
      // Check users
      final usersSnapshot = await _database.ref().child('users').get();
      if (usersSnapshot.exists) {
        final usersMap = usersSnapshot.value as Map<dynamic, dynamic>?;
        print('Users found: ${usersMap?.keys.length ?? 0}');
        usersMap?.keys.take(3).forEach((key) {
          print('  User ID: $key');
        });
      } else {
        print('No users found in database');
      }
      
      // Check items
      final itemsSnapshot = await _database.ref().child('items').get();
      if (itemsSnapshot.exists) {
        final itemsMap = itemsSnapshot.value as Map<dynamic, dynamic>?;
        print('Items found: ${itemsMap?.keys.length ?? 0}');
        itemsMap?.keys.take(3).forEach((key) {
          print('  Item ID: $key');
        });
      } else {
        print('No items found in database');
      }
      
      // Check requests
      final requestsSnapshot = await _database.ref().child('requests').get();
      if (requestsSnapshot.exists) {
        final requestsMap = requestsSnapshot.value as Map<dynamic, dynamic>?;
        print('Requests found: ${requestsMap?.keys.length ?? 0}');
        requestsMap?.entries.take(3).forEach((entry) {
          final requestData = Map<String, dynamic>.from(entry.value as Map);
          print('  Request ID: ${entry.key}');
          print('    Borrower: ${requestData['borrowerId']}');
          print('    Lender: ${requestData['lenderId']}');
          print('    Item: ${requestData['itemId']}');
          print('    Status: ${requestData['status']}');
        });
      } else {
        print('No requests found in database');
      }
      
      print('=== END DATABASE DEBUG ===');
    } catch (e) {
      print('Error during database debug: $e');
    }
  }

  // Utility method to create placeholder users for existing requests
  Future<void> createPlaceholderUsersForRequests() async {
    try {
      print('=== CREATING PLACEHOLDER USERS ===');
      
      // Get all requests
      final requestsSnapshot = await _database.ref().child('requests').get();
      if (!requestsSnapshot.exists) {
        print('No requests found, no placeholder users needed');
        return;
      }
      
      final requestsMap = requestsSnapshot.value as Map<dynamic, dynamic>;
      final userIdsNeeded = <String>{};
      
      // Collect all unique user IDs from requests
      requestsMap.entries.forEach((entry) {
        final requestData = Map<String, dynamic>.from(entry.value as Map);
        userIdsNeeded.add(requestData['borrowerId'] as String);
        userIdsNeeded.add(requestData['lenderId'] as String);
      });
      
      print('Found ${userIdsNeeded.length} unique user IDs in requests');
      
      // Check which users already exist
      final existingUsers = <String>[];
      for (final userId in userIdsNeeded) {
        final userExists = await _database.ref().child('users').child(userId).get();
        if (userExists.exists) {
          existingUsers.add(userId);
        }
      }
      
      print('${existingUsers.length} users already exist');
      final usersToCreate = userIdsNeeded.where((id) => !existingUsers.contains(id)).toList();
      print('Need to create ${usersToCreate.length} placeholder users');
      
      // Create placeholder users
      for (int i = 0; i < usersToCreate.length; i++) {
        final userId = usersToCreate[i];
        final placeholderUser = UserModel(
          uid: userId,
          name: 'User ${i + 1}',  // Placeholder name
          email: 'user${i + 1}@example.com',  // Placeholder email
          phone: '000-000-0000',  // Placeholder phone
          location: 'Unknown Location',  // Placeholder location
        );
        
        print('Creating placeholder user: ${userId} -> ${placeholderUser.name}');
        await createUser(placeholderUser);
      }
      
      print('=== PLACEHOLDER USERS CREATED ===');
    } catch (e) {
      print('Error creating placeholder users: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}
