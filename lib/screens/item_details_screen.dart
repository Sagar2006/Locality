import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/models/rental_model.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/providers/theme_provider.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/database_service.dart';
import 'package:provider/provider.dart';

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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = isDark ? const Color(0xFF38e07b) : const Color(0xFF38e07b);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Custom Header
                    Container(
                      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? const Color(0xFF1C1C1E).withOpacity(0.8)
                          : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Item Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontFamily: 'Spline Sans',
                              ),
                            ),
                          ),
                          const SizedBox(width: 40), // Balance the back button
                        ],
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Carousel
                            SizedBox(
                              height: 320,
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
                                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                                          child: Center(
                                            child: Icon(
                                              Icons.image,
                                              color: isDark ? Colors.grey[600] : Colors.grey,
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
                                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: isDark ? Colors.grey[600] : Colors.grey,
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
                                              color: primaryColor,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  // Image indicators
                                  if (widget.item.imageUrls.length > 1)
                                    Positioned(
                                      bottom: 16,
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
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Item Details
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Price
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.item.name,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                            fontFamily: 'Spline Sans',
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.item.pricePerDay != null
                                            ? '\$${widget.item.pricePerDay!.toStringAsFixed(0)}'
                                            : '\$${widget.item.pricePerHour!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontFamily: 'Spline Sans',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),
                                  Text(
                                    widget.item.pricePerDay != null ? '/day' : '/hour',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontFamily: 'Spline Sans',
                                    ),
                                  ),

                                  // Description
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.item.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontFamily: 'Spline Sans',
                                      height: 1.5,
                                    ),
                                  ),

                                  // Category and Location
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          widget.item.category,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.item.location,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Rating
                                  if (widget.item.ratingCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.item.rating.toStringAsFixed(1)} (${widget.item.ratingCount} reviews)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Availability Section
                            Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Availability',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontFamily: 'Spline Sans',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () => _showDatePicker(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                                        ),
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
                                              color: _startDate != null
                                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                              fontFamily: 'Spline Sans',
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Total Price Calculation
                                  if (_startDate != null && _endDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Days:',
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                    fontFamily: 'Spline Sans',
                                                  ),
                                                ),
                                                Text(
                                                  '${_endDate!.difference(_startDate!).inDays + 1}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                    fontFamily: 'Spline Sans',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Total:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                    fontFamily: 'Spline Sans',
                                                  ),
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
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                    fontFamily: 'Spline Sans',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Listed By Section
                            Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Listed by',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontFamily: 'Spline Sans',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_owner != null)
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                                          child: _owner!.profilePicUrl != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(28),
                                                  child: Image.network(
                                                    _owner!.profilePicUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 56,
                                                    height: 56,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.person,
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _owner!.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  fontFamily: 'Spline Sans',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Member since 2021',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontFamily: 'Spline Sans',
                                                ),
                                              ),
                                              if (_owner!.ratingCount > 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${_owner!.rating.toStringAsFixed(1)} (${_owner!.ratingCount})',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Button
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: _authService.currentUser?.uid == widget.item.ownerId
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  'You are the owner of this item',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontFamily: 'Spline Sans',
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: (_isRequestingRental || _hasPendingRequest) ? null : _requestRental,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: _isRequestingRental
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Text(
                                      _hasPendingRequest ? 'Request Sent' : 'Rent Now',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Spline Sans',
                                      ),
                                    ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
