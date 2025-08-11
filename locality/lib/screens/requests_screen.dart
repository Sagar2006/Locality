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
      
      // Load incoming (lender) requests
      final incomingRequests = await _databaseService.getRentalRequestsByLender(currentUser.uid);
      
      // Load outgoing (borrower) requests
      final outgoingRequests = await _databaseService.getRentalRequestsByBorrower(currentUser.uid);
      
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
    
    // Fetch users
    for (final userId in userIds) {
      if (!_usersCache.containsKey(userId)) {
        final user = await _databaseService.getUser(userId);
        if (user != null) {
          _usersCache[userId] = user;
        }
      }
    }
    
    // Fetch items
    for (final itemId in itemIds) {
      if (!_itemsCache.containsKey(itemId)) {
        final item = await _databaseService.getItem(itemId);
        if (item != null) {
          _itemsCache[itemId] = item;
        }
      }
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
            price: item.price,
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
                              
                              if (borrower == null || item == null) {
                                return const ListTile(
                                  title: Text('Loading request details...'),
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
                                return const ListTile(
                                  title: Text('Loading request details...'),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name and price
            Row(
              children: [
                if (item.imageUrls.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrls[0]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.price.toStringAsFixed(2)} / day',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Request details
            Row(
              children: [
                CircleAvatar(
                  child: Text(user.name[0]),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncoming ? 'Requested by ${user.name}' : 'Request to ${user.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text('${formatter(startDate)} - ${formatter(endDate)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status and total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    request.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Total: \$${request.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            // Action buttons for incoming requests
            if (isIncoming && request.status == RentalStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateRequestStatus(request, RentalStatus.declined),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _updateRequestStatus(request, RentalStatus.accepted),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ),
            
            // Cancel button for outgoing pending requests
            if (!isIncoming && request.status == RentalStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateRequestStatus(request, RentalStatus.canceled),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ],
                ),
              ),
            
            // Complete button for accepted requests
            if (request.status == RentalStatus.accepted)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateRequestStatus(request, RentalStatus.completed),
                      child: const Text('Mark as Completed'),
                    ),
                  ],
                ),
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
