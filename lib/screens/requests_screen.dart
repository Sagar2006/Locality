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
      
      print('Loading requests for user: ${currentUser.uid}');
      
      // Load incoming (lender) requests
      final incomingRequests = await _databaseService.getRentalRequestsByLender(currentUser.uid);
      print('Incoming requests count: ${incomingRequests.length}');
      
      // Load outgoing (borrower) requests
      final outgoingRequests = await _databaseService.getRentalRequestsByBorrower(currentUser.uid);
      print('Outgoing requests count: ${outgoingRequests.length}');
      
      // Debug: Print request details
      for (final request in outgoingRequests) {
        print('Outgoing request: ${request.id}, item: ${request.itemId}, status: ${request.status}');
      }
      
      // Preload users and items for both lists
      await _preloadUsersAndItems([...incomingRequests, ...outgoingRequests]);
      
      setState(() {
        _incomingRequests = incomingRequests;
        _outgoingRequests = outgoingRequests;
        _isLoadingIncoming = false;
        _isLoadingOutgoing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingIncoming = false;
        _isLoadingOutgoing = false;
      });
      print('Error loading requests: $e');
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
    
    print('Preloading ${userIds.length} users and ${itemIds.length} items');
    
    // Fetch users
    for (final userId in userIds) {
      if (!_usersCache.containsKey(userId)) {
        print('Fetching user: $userId');
        final user = await _databaseService.getUser(userId);
        if (user != null) {
          _usersCache[userId] = user;
          print('Loaded user: ${user.name}');
        } else {
          print('User not found: $userId');
        }
      }
    }
    
    // Fetch items
    for (final itemId in itemIds) {
      if (!_itemsCache.containsKey(itemId)) {
        print('Fetching item: $itemId');
        final item = await _databaseService.getItem(itemId);
        if (item != null) {
          _itemsCache[itemId] = item;
          print('Loaded item: ${item.name}');
        } else {
          print('Item not found: $itemId');
        }
      }
    }
    
    print('Cache now contains ${_usersCache.length} users and ${_itemsCache.length} items');
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_usersCache.containsKey(userId)) return;
    try {
      final user = await _databaseService.getUser(userId);
      if (user != null) {
        setState(() {
          _usersCache[userId] = user;
        });
      } else {
        print('ensureUserLoaded: user not found $userId');
      }
    } catch (e) {
      print('ensureUserLoaded error for $userId: $e');
    }
  }

  Future<void> _ensureItemLoaded(String itemId) async {
    if (_itemsCache.containsKey(itemId)) return;
    try {
      final item = await _databaseService.getItem(itemId);
      if (item != null) {
        setState(() {
          _itemsCache[itemId] = item;
        });
      } else {
        print('ensureItemLoaded: item not found $itemId');
      }
    } catch (e) {
      print('ensureItemLoaded error for $itemId: $e');
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Request #${request.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Status: ${request.status}'),
                                        Text('Borrower ID: ${request.borrowerId}'),
                                        Text('Item ID: ${request.itemId}'),
                                        if (borrower == null)
                                          Text('Missing borrower data', style: const TextStyle(color: Colors.red)),
                                        if (item == null)
                                          Text('Missing item data', style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (borrower == null)
                                              OutlinedButton(
                                                onPressed: () => _ensureUserLoaded(request.borrowerId),
                                                child: const Text('Retry Borrower'),
                                              ),
                                            const SizedBox(width: 8),
                                            if (item == null)
                                              OutlinedButton(
                                                onPressed: () => _ensureItemLoaded(request.itemId),
                                                child: const Text('Retry Item'),
                                              ),
                                          ],
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Request #${request.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Status: ${request.status}'),
                                        Text('Lender ID: ${request.lenderId}'),
                                        Text('Item ID: ${request.itemId}'),
                                        if (lender == null)
                                          Text('Missing lender data', style: const TextStyle(color: Colors.red)),
                                        if (item == null)
                                          Text('Missing item data', style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (lender == null)
                                              OutlinedButton(
                                                onPressed: () => _ensureUserLoaded(request.lenderId),
                                                child: const Text('Retry Lender'),
                                              ),
                                            const SizedBox(width: 8),
                                            if (item == null)
                                              OutlinedButton(
                                                onPressed: () => _ensureItemLoaded(request.itemId),
                                                child: const Text('Retry Item'),
                                              ),
                                          ],
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
