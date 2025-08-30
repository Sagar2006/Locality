
import 'package:flutter/material.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/screens/add_item_screen.dart';
import 'package:locality/screens/bookings_screen.dart';
import 'package:locality/screens/profile_screen.dart';
import 'package:locality/services/database_service.dart';
import 'package:locality/screens/item_description_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/category_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Item> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedNav = 0;
  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'All',
      'svg': 'assets/categoryicons/all.svg',
    },
    {
      'label': 'Electronics',
      'svg': 'assets/categoryicons/electronics.svg',
    },
    {
      'label': 'Sports',
      'svg': 'assets/categoryicons/sports.svg',
    },
    {
      'label': 'Entertainment',
      'svg': 'assets/categoryicons/entertainment.svg',
    },
    {
      'label': 'Beauty',
      'svg': 'assets/categoryicons/beauty.svg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await _databaseService.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF5F6FA), // slightly dimmer than white
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Center(
                child: const Text(
                  'locality',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF232B38)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'What are you looking for?',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C6B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return CategoryTile(
                      label: cat['label'],
                      svgAsset: cat['svg'],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Items',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C6B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? const Center(child: Text('No items found'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            String priceText = '';
                            String rateText = '';
                            if (item.pricePerDay != null) {
                              priceText = '₹${item.pricePerDay!.toStringAsFixed(0)}';
                              rateText = '/day';
                            } else if (item.pricePerHour != null) {
                              priceText = '₹${item.pricePerHour!.toStringAsFixed(0)}';
                              rateText = '/hour';
                            } else {
                              priceText = 'N/A';
                              rateText = '';
                            }
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItemDescriptionPage(item: item),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.13),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: item.imageUrls.isNotEmpty
                                            ? Image.network(
                                                item.imageUrls.first,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: const Color(0xFFF3F6FA),
                                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                              ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF232B38),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.pricePerDay != null
                                                  ? 'Daily Rate'
                                                  : item.pricePerHour != null
                                                      ? 'Hourly Rate'
                                                      : 'No Rate',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text(
                                                  priceText,
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF232B38)),
                                                ),
                                                Text(
                                                  rateText,
                                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2196F3),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          elevation: 0,
                                        ),
                                        child: const Text('Book'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
          ),
        ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNav,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingsScreen()),
            );
            // Optionally reload items if needed
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            // Optionally reload items if needed
          }
          setState(() {
            _selectedNav = index;
          });
        },
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
          _loadItems();
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
