import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/models/rental_model.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/database_service.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;

  const ItemDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  late PageController _imagePageController;
  UserModel? _owner;
  bool _isLoading = false;
  bool _isRequestingRental = false;
  bool _hasPendingRequest = false;
  DateTime? _startDate;
  DateTime? _endDate;

  int _currentImageIndex = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _loadOwnerData();
    _checkPendingRequest();
  }

  Future<void> _checkPendingRequest() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    
    try {
      final hasPending = await _databaseService.hasPendingRequestForItem(currentUser.uid, widget.item.id);
      if (mounted) {
        setState(() {
          _hasPendingRequest = hasPending;
        });
        print('Pending request status: $hasPending');
      }
    } catch (e) {
      print('Error checking pending request: $e');
    }
  }

  Future<void> _loadOwnerData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final owner = await _databaseService.getUser(widget.item.ownerId);
      setState(() {
        _owner = owner;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load owner information';
        _isLoading = false;
      });
      print('Error loading owner data: $e');
    }
  }
  
  Future<void> _showDatePicker(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 7)),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
    }
  }
  
  Future<void> _requestRental() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select rental dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isRequestingRental = true;
    });
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if trying to rent own item
      if (currentUser.uid == widget.item.ownerId) {
        throw Exception('You cannot rent your own item');
      }
      
      // Prevent duplicate pending requests
      final hasPending = await _databaseService.hasPendingRequestForItem(currentUser.uid, widget.item.id);
      if (hasPending) {
        throw Exception('You have already sent a request for this item.');
      }
      
      // Calculate rental duration in days
      final difference = _endDate!.difference(_startDate!).inDays + 1;
      double totalPrice = 0;
      if (widget.item.pricePerDay != null) {
        totalPrice = widget.item.pricePerDay! * difference;
      } else if (widget.item.pricePerHour != null) {
        totalPrice = widget.item.pricePerHour! * difference * 24;
      }
      
      final rentalRequest = RentalRequest(
        id: '', // Will be set by database service
        itemId: widget.item.id,
        lenderId: widget.item.ownerId,
        borrowerId: currentUser.uid,
        status: RentalStatus.pending,
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: totalPrice,
      );
      
      await _databaseService.createRentalRequest(rentalRequest);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental request sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _startDate = null;
        _endDate = null;
        _hasPendingRequest = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingRental = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: widget.item.imageUrls.isEmpty ? 1 : widget.item.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            if (widget.item.imageUrls.isEmpty) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 80,
                                  ),
                                ),
                              );
                            }
                            
                            return Image.network(
                              widget.item.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 80,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        
                        // Image indicators
                        if (widget.item.imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.item.imageUrls.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.blue
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name and Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (widget.item.pricePerDay != null)
                                  Text(
                                    '\$${widget.item.pricePerDay!.toStringAsFixed(2)} / day',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                if (widget.item.pricePerHour != null)
                                  Text(
                                    '\$${widget.item.pricePerHour!.toStringAsFixed(2)} / hour',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Category and Location
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.item.category,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.item.location,
                                style: const TextStyle(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        // Rating
                        if (widget.item.ratingCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.item.rating.toStringAsFixed(1)} (${widget.item.ratingCount} reviews)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Owner Info
                        const SizedBox(height: 24),
                        const Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_owner != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: _owner!.profilePicUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        _owner!.profilePicUrl!,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person),
                            ),
                            title: Text(_owner!.name),
                            subtitle: _owner!.ratingCount > 0
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_owner!.rating.toStringAsFixed(1)} (${_owner!.ratingCount})',
                                      ),
                                    ],
                                  )
                                : const Text('No ratings yet'),
                          ),
                        
                        // Description
                        const SizedBox(height: 24),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.item.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        
                        // Rental Period Selection
                        const SizedBox(height: 24),
                        const Text(
                          'Select Rental Period',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showDatePicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                      : 'Select dates',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _startDate != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        
                        // Total Price Calculation
                        if (_startDate != null && _endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Days:'),
                                    Text('${_endDate!.difference(_startDate!).inDays + 1}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (widget.item.pricePerDay != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Price per day:'),
                                      Text('\$${widget.item.pricePerDay!.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                if (widget.item.pricePerHour != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Price per hour:'),
                                      Text('\$${widget.item.pricePerHour!.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      () {
                                        int days = _endDate != null && _startDate != null ? _endDate!.difference(_startDate!).inDays + 1 : 0;
                                        double total = 0;
                                        if (widget.item.pricePerDay != null) {
                                          total = widget.item.pricePerDay! * days;
                                        } else if (widget.item.pricePerHour != null) {
                                          total = widget.item.pricePerHour! * days * 24;
                                        }
                                        return '\$${total.toStringAsFixed(2)}';
                                      }(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _authService.currentUser?.uid == widget.item.ownerId
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Text(
                'You are the owner of this item',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: (_isRequestingRental || _hasPendingRequest) ? null : _requestRental,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isRequestingRental
                    ? const CircularProgressIndicator()
                    : Text(
                        _hasPendingRequest ? 'Request Sent' : 'Request to Rent',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
    );
  }
}
