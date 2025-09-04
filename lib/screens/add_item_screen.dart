import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/providers/theme_provider.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/cloudinary_service.dart';
import 'package:locality/services/database_service.dart';
import 'package:provider/provider.dart';

class AddItemScreen extends StatefulWidget {
  final Item? item;
  const AddItemScreen({Key? key, this.item}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedCategory = 'Electronics';
  final List<String> _categories = ['Electronics', 'Tools', 'Furniture', 'Vehicles', 'Sports', 'Others'];
  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  int _currentStep = 0;
  bool _isLoading = false;
  String _error = '';
  bool _isPricePerDay = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description;
      _priceController.text = widget.item!.pricePerDay?.toString() ?? widget.item!.pricePerHour?.toString() ?? '';
      _locationController.text = widget.item!.location;
      _selectedCategory = widget.item!.category;
      _existingImageUrls = List<String>.from(widget.item!.imageUrls);
      _isPricePerDay = widget.item!.pricePerDay != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitItem() async {
    if (_formKey.currentState!.validate()) {
      // At least one price must be set
      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        setState(() {
          _error = 'Please enter a valid price';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        List<String> newImageUrls = [];
        if (_selectedImages.isNotEmpty) {
          // Upload new images
          final List<File> files = _selectedImages.map((xFile) => File(xFile.path)).toList();
          newImageUrls = await _cloudinaryService.uploadMultipleImages(files);
          if (newImageUrls.isEmpty) {
            throw Exception('Failed to upload images');
          }
        }

        // Combine existing and new images
        final allImageUrls = [..._existingImageUrls, ...newImageUrls];
        if (allImageUrls.isEmpty) {
          setState(() {
            _error = 'Please add at least one image';
          });
          return;
        }

        if (widget.item == null) {
          // Add new item
          final item = Item(
            id: '',
            ownerId: currentUser.uid,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            pricePerDay: _isPricePerDay ? price : null,
            pricePerHour: !_isPricePerDay ? price : null,
            imageUrls: allImageUrls,
            location: _locationController.text.trim(),
          );
          await _databaseService.createItem(item);
        } else {
          // Update existing item
          final updatedItem = Item(
            id: widget.item!.id,
            ownerId: widget.item!.ownerId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            pricePerDay: _isPricePerDay ? price : null,
            pricePerHour: !_isPricePerDay ? price : null,
            imageUrls: allImageUrls,
            location: _locationController.text.trim(),
          );
          await _databaseService.updateItem(updatedItem);
        }

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildStepIndicator() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step 1: Details
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 0
                        ? (_currentStep == 0 ? primaryColor : (isDark ? Colors.grey[600] : Colors.grey[400]))
                        : (isDark ? Colors.grey[700] : Colors.grey[200]),
                  ),
                  child: _currentStep > 0
                      ? Icon(Icons.check, color: isDark ? Colors.white : Colors.black, size: 18)
                      : Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: _currentStep == 0 ? Colors.black : (isDark ? Colors.white : Colors.black),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentStep == 0 ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                  ),
                ),
              ],
            ),

            // Connector 1-2
            Container(
              width: 32,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 0 ? primaryColor : (isDark ? Colors.grey[700] : Colors.grey[300]),
            ),

            // Step 2: Location
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 1
                        ? (_currentStep == 1 ? primaryColor : (isDark ? Colors.grey[600] : Colors.grey[400]))
                        : (isDark ? Colors.grey[700] : Colors.grey[200]),
                  ),
                  child: _currentStep > 1
                      ? Icon(Icons.check, color: isDark ? Colors.white : Colors.black, size: 18)
                      : Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: _currentStep == 1 ? Colors.black : (isDark ? Colors.white : Colors.black),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentStep == 1 ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                  ),
                ),
              ],
            ),

            // Connector 2-3
            Container(
              width: 32,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 1 ? primaryColor : (isDark ? Colors.grey[700] : Colors.grey[300]),
            ),

            // Step 3: Photos
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 2
                        ? (_currentStep == 2 ? primaryColor : (isDark ? Colors.grey[600] : Colors.grey[400]))
                        : (isDark ? Colors.grey[700] : Colors.grey[200]),
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: _currentStep == 2 ? Colors.black : (isDark ? Colors.white : Colors.black),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentStep == 2 ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsStep() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Title
                Text(
                  'Item Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'Spline Sans',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: 'Spline Sans',
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Modern Sofa',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontFamily: 'Spline Sans',
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an item title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'Spline Sans',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: 'Spline Sans',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe your item in detail...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontFamily: 'Spline Sans',
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Category
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'Spline Sans',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: 'Spline Sans',
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  items: _categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontFamily: 'Spline Sans',
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Rental Price
                Text(
                  'Rental Price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'Spline Sans',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '\$',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                            fontFamily: 'Spline Sans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Spline Sans',
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                              fontFamily: 'Spline Sans',
                            ),
                            filled: false,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '/ day',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Spline Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _nextStep();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Spline Sans',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationStep() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return Column(
          children: [
            // Map Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDOSx81M328bpEhTeL9klc7PpxYYq_5NPYq2WJbuaFUz1vZj-ipyZWAyD9S10winNqWkP_kUwlBtOahzLu-EmlGYvMrI9FEhSx0Orj3jgHEpuaIdyKt9G6vU5raaZgkV89hmb6Z1Hoo0u7nVHf53ab5zYltV82ldprHY2oZNvVSjwHZDA6fDtLXgnFagCJwdvcg_B3Pi3tn1_lzepdShTnUO7GoL1vjC02Gk-jiop86vXjjrKkMkri0tefOlz3Q9-WAV7FIspQb06Zi',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Location Pin
                  Center(
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: primaryColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Panel
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set item location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontFamily: 'Spline Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pinpoint your item on the map or enter address.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Spline Sans',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search Input
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: 'Spline Sans',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for address',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontFamily: 'Spline Sans',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontFamily: 'Spline Sans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current Location Button
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement current location
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Use My Current Location',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Spline Sans',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_locationController.text.isNotEmpty || _searchController.text.isNotEmpty) {
                          _locationController.text = _searchController.text;
                          _nextStep();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Spline Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotosStep() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add photos of your item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontFamily: 'Spline Sans',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add up to 10 photos. Drag to reorder.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: 'Spline Sans',
                ),
              ),

              const SizedBox(height: 24),

              // Photo Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _existingImageUrls.length + _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  // Add Photo Button
                  if (index == _existingImageUrls.length + _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontFamily: 'Spline Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Existing Images
                  if (index < _existingImageUrls.length) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(_existingImageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Spline Sans',
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingImageUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Selected Images
                  final selectedIndex = index - _existingImageUrls.length;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[selectedIndex].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (index == 0 && _existingImageUrls.isEmpty)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Spline Sans',
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(selectedIndex),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Gallery Button
              OutlinedButton(
                onPressed: _pickImages,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: 'Spline Sans',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Camera Button
              OutlinedButton(
                onPressed: _pickImageFromCamera,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Take a Photo',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: 'Spline Sans',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Finish Listing Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Finish Listing',
                          style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
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
                        'List an Item',
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

              // Step Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _buildStepIndicator(),
              ),

              // Main Content
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildDetailsStep(),
                    _buildLocationStep(),
                    _buildPhotosStep(),
                  ],
                ),
              ),

              // Error Message
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),

          // Bottom Navigation
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.95) : Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', false, () {}),
                _buildNavItem(Icons.search, 'Search', false, () {}),
                _buildNavItem(Icons.add_box, 'List Item', true, () {}),
                _buildNavItem(Icons.inbox, 'Messages', false, () {}),
                _buildNavItem(Icons.person, 'My Rentals', false, () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = const Color(0xFF38e07b);

        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                size: 24,
                fill: isActive ? 1 : 0,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                  fontFamily: 'Spline Sans',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
