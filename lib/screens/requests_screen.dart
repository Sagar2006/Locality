import 'package:flutter/material.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/models/rental_model.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/database_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  _RequestsScreenState createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<RentalRequest> _incomingRequests = [];
  List<RentalRequest> _outgoingRequests = [];
  bool _isLoadingIncoming = true;
  bool _isLoadingOutgoing = true;
  String _error = '';
  
  Map<String, UserModel> _usersCache = {};
  Map<String, Item> _itemsCache = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh requests when screen becomes visible
    _loadRequests();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRequests() async {
    setState(() {
      _isLoadingIncoming = true;
      _isLoadingOutgoing = true;
      _error = '';
    });
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      print('RequestsScreen: Loading requests for user: ${currentUser.uid}');
      
      // Debug database structure first
      await _databaseService.debugDatabaseStructure();
      
      // Load incoming (lender) requests
      print('RequestsScreen: Loading incoming requests...');
      final incomingRequests = await _databaseService.getRentalRequestsByLender(currentUser.uid);
      print('RequestsScreen: Incoming requests count: ${incomingRequests.length}');
      
      // Load outgoing (borrower) requests
      print('RequestsScreen: Loading outgoing requests...');
      final outgoingRequests = await _databaseService.getRentalRequestsByBorrower(currentUser.uid);
      print('RequestsScreen: Outgoing requests count: ${outgoingRequests.length}');
      
      // Debug: Print request details
      for (final request in [...incomingRequests, ...outgoingRequests]) {
        print('RequestsScreen: Request ${request.id}: '
              'item=${request.itemId}, '
              'borrower=${request.borrowerId}, '
              'lender=${request.lenderId}, '
              'status=${request.status}');
      }
      
      // Preload users and items for both lists
      print('RequestsScreen: Preloading users and items...');
      await _preloadUsersAndItems([...incomingRequests, ...outgoingRequests]);
      
      setState(() {
        _incomingRequests = incomingRequests;
        _outgoingRequests = outgoingRequests;
        _isLoadingIncoming = false;
        _isLoadingOutgoing = false;
      });
      
      print('RequestsScreen: Successfully loaded all requests');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingIncoming = false;
        _isLoadingOutgoing = false;
      });
      print('RequestsScreen: Error loading requests: $e');
      print('RequestsScreen: Stack trace: ${StackTrace.current}');
    }
  }
  
  Future<void> _preloadUsersAndItems(List<RentalRequest> requests) async {
    // Collect unique user IDs and item IDs
    final userIds = <String>{};
    final itemIds = <String>{};
    
    for (final request in requests) {
      userIds.add(request.borrowerId);
      userIds.add(request.lenderId);
      itemIds.add(request.itemId);
    }
    
    print('RequestsScreen: Preloading ${userIds.length} users and ${itemIds.length} items');
    print('RequestsScreen: User IDs to load: $userIds');
    print('RequestsScreen: Item IDs to load: $itemIds');
    
    // Fetch users in parallel
    final userFutures = userIds.map((userId) async {
      if (!_usersCache.containsKey(userId)) {
        print('RequestsScreen: Fetching user: $userId');
        try {
          final user = await _databaseService.getUser(userId);
          if (user != null) {
            _usersCache[userId] = user;
            print('RequestsScreen: Loaded user: ${user.name} (ID: $userId)');
          } else {
            print('RequestsScreen: User not found: $userId');
          }
        } catch (e) {
          print('RequestsScreen: Error loading user $userId: $e');
        }
      } else {
        print('RequestsScreen: User $userId already in cache');
      }
    });
    
    // Fetch items in parallel
    final itemFutures = itemIds.map((itemId) async {
      if (!_itemsCache.containsKey(itemId)) {
        print('RequestsScreen: Fetching item: $itemId');
        try {
          final item = await _databaseService.getItem(itemId);
          if (item != null) {
            _itemsCache[itemId] = item;
            print('RequestsScreen: Loaded item: ${item.name} (ID: $itemId)');
          } else {
            print('RequestsScreen: Item not found: $itemId');
          }
        } catch (e) {
          print('RequestsScreen: Error loading item $itemId: $e');
        }
      } else {
        print('RequestsScreen: Item $itemId already in cache');
      }
    });
    
    // Wait for all futures to complete
    await Future.wait([...userFutures, ...itemFutures]);
    
    print('RequestsScreen: Cache now contains ${_usersCache.length} users and ${_itemsCache.length} items');
    print('RequestsScreen: User cache keys: ${_usersCache.keys.toList()}');
    print('RequestsScreen: Item cache keys: ${_itemsCache.keys.toList()}');
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_usersCache.containsKey(userId)) return;
    
    print('RequestsScreen: Manually loading user: $userId');
    try {
      final user = await _databaseService.getUser(userId);
      if (user != null) {
        setState(() {
          _usersCache[userId] = user;
        });
        print('RequestsScreen: Successfully loaded user: ${user.name}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded user data'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('RequestsScreen: User not found in database: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data not found in database'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('RequestsScreen: Error loading user $userId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _ensureItemLoaded(String itemId) async {
    if (_itemsCache.containsKey(itemId)) return;
    
    print('RequestsScreen: Manually loading item: $itemId');
    try {
      final item = await _databaseService.getItem(itemId);
      if (item != null) {
        setState(() {
          _itemsCache[itemId] = item;
        });
        print('RequestsScreen: Successfully loaded item: ${item.name}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded item data'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('RequestsScreen: Item not found in database: $itemId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item data not found in database'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('RequestsScreen: Error loading item $itemId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load item data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _updateRequestStatus(RentalRequest request, RentalStatus newStatus) async {
    try {
      final updatedRequest = RentalRequest(
        id: request.id,
        itemId: request.itemId,
        lenderId: request.lenderId,
        borrowerId: request.borrowerId,
        status: newStatus,
        startDate: request.startDate,
        endDate: request.endDate,
        totalPrice: request.totalPrice,
      );
      
      await _databaseService.updateRentalRequest(updatedRequest);
      
      // Also update item status if needed
      if (newStatus == RentalStatus.accepted) {
        final item = _itemsCache[request.itemId];
        if (item != null) {
          final updatedItem = Item(
            id: item.id,
            ownerId: item.ownerId,
            name: item.name,
            description: item.description,
            category: item.category,
            pricePerDay: item.pricePerDay,
            pricePerHour: item.pricePerHour,
            imageUrls: item.imageUrls,
            status: ItemStatus.rented,
            rating: item.rating,
            ratingCount: item.ratingCount,
            location: item.location,
          );
          
          await _databaseService.updateItem(updatedItem);
        }
      }
      
      // Reload requests
      _loadRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${newStatus.toString().split('.').last} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'debug') {
                print('=== MANUAL DEBUG TRIGGER ===');
                await _databaseService.debugDatabaseStructure();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debug info printed to console'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (value == 'create_users') {
                print('=== CREATING PLACEHOLDER USERS ===');
                try {
                  await _databaseService.createPlaceholderUsersForRequests();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Placeholder users created successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Reload requests after creating users
                  _loadRequests();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create users: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20),
                    SizedBox(width: 8),
                    Text('Debug Database'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'create_users',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 20),
                    SizedBox(width: 8),
                    Text('Create Missing Users'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Incoming Requests Tab
                _isLoadingIncoming
                    ? const Center(child: CircularProgressIndicator())
                    : _incomingRequests.isEmpty
                        ? const Center(
                            child: Text('No incoming rental requests'),
                          )
                        : ListView.builder(
                            itemCount: _incomingRequests.length,
                            itemBuilder: (context, index) {
                              final request = _incomingRequests[index];
                              final borrower = _usersCache[request.borrowerId];
                              final item = _itemsCache[request.itemId];
                              
                              print('=== INCOMING REQUEST DEBUG ===');
                              print('Request ID: ${request.id}');
                              print('Borrower ID: ${request.borrowerId}');
                              print('Lender ID: ${request.lenderId}');
                              print('Item ID: ${request.itemId}');
                              print('Borrower found: ${borrower != null}');
                              print('Item found: ${item != null}');
                              print('Cache keys - Users: ${_usersCache.keys.toList()}');
                              print('Cache keys - Items: ${_itemsCache.keys.toList()}');
                              print('===============================');
                              
                              if (borrower == null || item == null) {
                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  color: Colors.red[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.red[700], size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Data Loading Issue',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[700],
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Request #${request.id.substring(0, 8)}...',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Status: ${request.status.toString().split('.').last}'),
                                              const SizedBox(height: 4),
                                              Text('Borrower ID: ${request.borrowerId}'),
                                              const SizedBox(height: 4),
                                              Text('Item ID: ${request.itemId}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.info, color: Colors.blue[700], size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Troubleshooting',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'This happens when users were not properly saved during registration. Use the menu (⋮) above to "Create Missing Users" to fix this issue.',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (borrower == null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.person_off, color: Colors.red, size: 16),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Missing borrower data',
                                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (item == null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.inventory_2_outlined, color: Colors.red, size: 16),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Missing item data',
                                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            if (borrower == null)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _ensureUserLoaded(request.borrowerId),
                                                  icon: const Icon(Icons.refresh, size: 16),
                                                  label: const Text('Retry Borrower'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                    side: const BorderSide(color: Colors.blue),
                                                  ),
                                                ),
                                              ),
                                            if (borrower == null && item == null)
                                              const SizedBox(width: 8),
                                            if (item == null)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _ensureItemLoaded(request.itemId),
                                                  icon: const Icon(Icons.refresh, size: 16),
                                                  label: const Text('Retry Item'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                    side: const BorderSide(color: Colors.blue),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _loadRequests,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Reload All Data'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return _buildRequestCard(
                                request: request,
                                user: borrower,
                                item: item,
                                isIncoming: true,
                              );
                            },
                          ),
                
                // Outgoing Requests Tab
                _isLoadingOutgoing
                    ? const Center(child: CircularProgressIndicator())
                    : _outgoingRequests.isEmpty
                        ? const Center(
                            child: Text('No outgoing rental requests'),
                          )
                        : ListView.builder(
                            itemCount: _outgoingRequests.length,
                            itemBuilder: (context, index) {
                              final request = _outgoingRequests[index];
                              final lender = _usersCache[request.lenderId];
                              final item = _itemsCache[request.itemId];
                              
                              if (lender == null || item == null) {
                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  color: Colors.orange[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.orange[700], size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Data Loading Issue',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Request #${request.id.substring(0, 8)}...',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Status: ${request.status.toString().split('.').last}'),
                                              const SizedBox(height: 4),
                                              Text('Lender ID: ${request.lenderId}'),
                                              const SizedBox(height: 4),
                                              Text('Item ID: ${request.itemId}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.info, color: Colors.blue[700], size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Troubleshooting',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'This happens when users were not properly saved during registration. Use the menu (⋮) above to "Create Missing Users" to fix this issue.',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (lender == null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.person_off, color: Colors.orange, size: 16),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Missing lender data',
                                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (item == null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 16),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Missing item data',
                                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            if (lender == null)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _ensureUserLoaded(request.lenderId),
                                                  icon: const Icon(Icons.refresh, size: 16),
                                                  label: const Text('Retry Lender'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                    side: const BorderSide(color: Colors.blue),
                                                  ),
                                                ),
                                              ),
                                            if (lender == null && item == null)
                                              const SizedBox(width: 8),
                                            if (item == null)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _ensureItemLoaded(request.itemId),
                                                  icon: const Icon(Icons.refresh, size: 16),
                                                  label: const Text('Retry Item'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                    side: const BorderSide(color: Colors.blue),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _loadRequests,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Reload All Data'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return _buildRequestCard(
                                request: request,
                                user: lender,
                                item: item,
                                isIncoming: false,
                              );
                            },
                          ),
              ],
            ),
    );
  }
  
  Widget _buildRequestCard({
    required RentalRequest request,
    required UserModel user,
    required Item item,
    required bool isIncoming,
  }) {
    final statusColor = _getStatusColor(request.status);
    final startDate = request.startDate;
    final endDate = request.endDate;
    final formatter = (DateTime date) =>
        '${date.month}/${date.day}/${date.year}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with request type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isIncoming ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isIncoming ? 'INCOMING REQUEST' : 'OUTGOING REQUEST',
                style: TextStyle(
                  color: isIncoming ? Colors.blue[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Item details row
            Row(
              children: [
                // Item image
                if (item.imageUrls.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrls[0]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                
                // Item and user info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Item category and location
                      Text(
                        '${item.category} • ${item.location}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // User info
                      Row(
                        children: [
                          Icon(
                            isIncoming ? Icons.person : Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncoming ? 'From: ${user.name}' : 'To: ${user.name}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rental period and price info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rental period
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rental Period',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatter(startDate)} - ${formatter(endDate)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      // Total price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${request.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Status and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    request.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Action buttons row
                if (request.status == RentalStatus.pending) ...[
                  if (isIncoming) ...[
                    // Lender actions (Accept/Decline)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _updateRequestStatus(request, RentalStatus.declined),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _updateRequestStatus(request, RentalStatus.accepted),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Borrower actions (Cancel)
                    OutlinedButton.icon(
                      onPressed: () => _updateRequestStatus(request, RentalStatus.canceled),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ] else if (request.status == RentalStatus.accepted) ...[
                  // Mark as completed button
                  ElevatedButton.icon(
                    onPressed: () => _updateRequestStatus(request, RentalStatus.completed),
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return Colors.orange;
      case RentalStatus.accepted:
        return Colors.green;
      case RentalStatus.completed:
        return Colors.blue;
      case RentalStatus.declined:
      case RentalStatus.canceled:
        return Colors.red;
    }
  }
}
