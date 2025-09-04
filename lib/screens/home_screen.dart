
import 'package:flutter/material.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/screens/add_item_screen.dart';
import 'package:locality/screens/bookings_screen.dart';
import 'package:locality/screens/profile_screen.dart';
import 'package:locality/services/database_service.dart';
import 'package:locality/screens/item_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:locality/providers/theme_provider.dart';
import 'package:locality/services/sample_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SampleDataService _sampleDataService = SampleDataService();
  List<Item> _items = [];
  List<Item> _featuredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _selectedNav = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Electronics',
      'icon': Icons.tv,
      'backgroundColor': const Color(0xFFDCFCE7), // primary-100
      'iconColor': const Color(0xFF16A34A), // primary-600
    },
    {
      'label': 'Home Goods',
      'icon': Icons.chair,
      'backgroundColor': const Color(0xFFF3E8FF), // purple-100
      'iconColor': const Color(0xFF7C3AED), // purple-600
    },
    {
      'label': 'Sports',
      'icon': Icons.sports_basketball,
      'backgroundColor': const Color(0xFFFFEDD5), // orange-100
      'iconColor': const Color(0xFFEA580C), // orange-600
    },
    {
      'label': 'Clothing',
      'icon': Icons.checkroom,
      'backgroundColor': const Color(0xFFE0F2FE), // sky-100
      'iconColor': const Color(0xFF0284C7), // sky-600
    },
    {
      'label': 'Tools',
      'icon': Icons.construction,
      'backgroundColor': const Color(0xFFFFF1F2), // rose-100
      'iconColor': const Color(0xFFE11D48), // rose-600
    },
    {
      'label': 'Books',
      'icon': Icons.book,
      'backgroundColor': const Color(0xFFFFF7ED), // amber-100
      'iconColor': const Color(0xFFD97706), // amber-600
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
    try {
      final items = await _databaseService.getItems();
      print('HomeScreen: Loaded ${items.length} items from database');
      for (var item in items) {
        print('Item: ${item.name}, Rating: ${item.rating}, Status: ${item.status}');
      }
      setState(() {
        _items = items;
        _featuredItems = items.where((item) => item.rating >= 4.0).take(4).toList();
        print('HomeScreen: Featured items: ${_featuredItems.length}');
        _isLoading = false;
      });
    } catch (e) {
      print('HomeScreen: Error loading items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSampleData() async {
    try {
      await _sampleDataService.addSampleItems();
      await _loadItems(); // Reload items after adding sample data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample items added successfully!')),
      );
    } catch (e) {
      print('Error adding sample data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding sample data: $e')),
      );
    }
  }

  List<Item> get _filteredItems {
    List<Item> filtered = _items;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF111714)
              : Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          _buildSearchBar(),

                          const SizedBox(height: 16),

                          // Filter Buttons
                          _buildFilterButtons(),

                          const SizedBox(height: 24),

                          // Categories
                          _buildCategories(),

                          const SizedBox(height: 24),

                          // Featured Items
                          _buildFeaturedItems(),

                          const SizedBox(height: 24),

                          // All Items
                          _buildAllItems(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Navigation
                _buildBottomNavigation(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40), // Spacer for centering
              Text(
                'Rentify',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Spline Sans',
                ),
              ),
              Row(
                children: [
                  // Theme Toggle Button
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF1C2620)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                        size: 20,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  // Add Sample Data Button
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF1C2620)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                        size: 20,
                      ),
                      onPressed: _addSampleData,
                      padding: EdgeInsets.zero,
                      tooltip: 'Add Sample Data',
                    ),
                  ),
                  // Settings Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF1C2620)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF1C2620)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(25),
            border: themeProvider.isDarkMode
                ? null
                : Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: 'Search for items',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9EB7A8)
                    : const Color(0xFF6B7280),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9EB7A8)
                    : const Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('Filters', Icons.tune),
          const SizedBox(width: 8),
          _buildFilterButton('Price', Icons.expand_more),
          const SizedBox(width: 8),
          _buildFilterButton('Distance', Icons.expand_more),
          const SizedBox(width: 8),
          _buildFilterButton('Availability', Icons.expand_more),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? const Color(0xFF1C2620) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: themeProvider.isDarkMode
                ? null
                : Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : const Color(0xFF374151),
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Spline Sans',
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) => _buildCategoryItem(category, themeProvider.isDarkMode)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDarkMode ? null : category['backgroundColor'],
              gradient: isDarkMode
                  ? LinearGradient(
                      colors: [
                        (category['backgroundColor'] as Color).withOpacity(0.8),
                        category['iconColor'] as Color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              category['icon'],
              color: isDarkMode ? Colors.white : category['iconColor'],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category['label'],
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItems() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Items',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Spline Sans',
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _featuredItems.length,
              itemBuilder: (context, index) {
                final item = _featuredItems[index];
                return _buildFeaturedItemCard(item, themeProvider.isDarkMode);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedItemCard(Item item, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(item: item),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: item.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrls[0]),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDarkMode ? const Color(0xFF1C2620) : const Color(0xFFF3F4F6),
            ),
            child: item.imageUrls.isEmpty
                ? Icon(
                    Icons.inventory_2,
                    color: isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280),
                    size: 40,
                  )
                : null,
          ),

          const SizedBox(height: 8),

          // Item Name
          Text(
            item.name,
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Price and Distance
          Text(
            '\$${item.pricePerDay?.toStringAsFixed(0) ?? '0'}/day · 2 mi',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllItems() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_filteredItems.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Items',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Spline Sans',
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 64,
                      color: themeProvider.isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to list an item!',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Items',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Spline Sans',
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildFeaturedItemCard(item, themeProvider.isDarkMode);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF1C2620)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            color: themeProvider.isDarkMode ? const Color(0xFF111714) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Home', themeProvider.isDarkMode),
              _buildNavItem(1, Icons.search, 'Search', themeProvider.isDarkMode),
              _buildNavItem(2, Icons.add_box, 'List Item', themeProvider.isDarkMode),
              _buildNavItem(3, Icons.chat_bubble, 'Messages', themeProvider.isDarkMode),
              _buildNavItem(4, Icons.person, 'My Rentals', themeProvider.isDarkMode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDarkMode) {
    final isSelected = _selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNav = index;
        });
        // Handle navigation here
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            // Search screen
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddItemScreen()),
            );
            break;
          case 3:
            // Messages screen
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF22C55E)
                : (isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280)),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF22C55E)
                  : (isDarkMode ? const Color(0xFF9EB7A8) : const Color(0xFF6B7280)),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
