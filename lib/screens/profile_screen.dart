import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/models/item_model.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/cloudinary_service.dart';
import 'package:locality/services/database_service.dart';
import 'package:locality/screens/auth/login_screen.dart';
import 'package:locality/screens/my_items_screen.dart';
import 'package:locality/screens/add_item_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _error = '';
  XFile? _selectedImage;

  // Mock data for demonstration - in real app, this would come from database
  int _itemsListed = 0;
  int _itemsRented = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print("ProfileScreen: Loading user profile...");
      // Force refresh auth state to ensure we have the latest user info
      await _authService.refreshUser();
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print("ProfileScreen: No authenticated user found");
        // Set an error that guides the user instead of throwing an exception
        setState(() {
          _isLoading = false;
          _error = 'You need to log in first. Please go to the login screen.';
        });
        return;
      }
      
      print("ProfileScreen: Current user ID: ${currentUser.uid}");
      var user = await _databaseService.getUser(currentUser.uid);
      print("ProfileScreen: User data retrieved: ${user != null ? 'Success' : 'NULL'}");
      
      if (user == null) {
        // If user is null, try to create a default user profile
        print("ProfileScreen: Attempting to create default user profile");
        try {
          final newUser = UserModel(
            uid: currentUser.uid,
            name: currentUser.displayName ?? 'New User',
            email: currentUser.email ?? '',
            phone: '',
            location: '',
          );
          await _databaseService.createUser(newUser);
          print("ProfileScreen: Created default user profile");
          // Try fetching the user again
          final createdUser = await _databaseService.getUser(currentUser.uid);
          if (createdUser != null) {
            print("ProfileScreen: Successfully created and retrieved user");
            user = createdUser;
          }
        } catch (e) {
          print("ProfileScreen: Error creating default user: $e");
        }
      }
      
      final allItems = await _databaseService.getItems();

      // Calculate real statistics
      final userItems = allItems.where((item) => item.ownerId.trim() == currentUser.uid.trim()).toList();
      final rentedItems = userItems.where((item) => item.status == ItemStatus.rented).length;
      final totalEarnings = userItems.fold<double>(0.0, (sum, item) => sum + (item.pricePerDay ?? 0));

      setState(() {
        _user = user;
        _itemsListed = userItems.length;
        _itemsRented = rentedItems;
        _totalEarnings = totalEarnings;

        // Initialize text controllers
        if (user != null) {
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _locationController.text = user.location;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading user profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _error = '';
      });

      try {
        final currentUser = _authService.currentUser;
        if (currentUser == null || _user == null) {
          throw Exception('User not authenticated');
        }

        String? profilePicUrl = _user!.profilePicUrl;

        // Upload new profile picture if selected
        if (_selectedImage != null) {
          final imageUrl = await _cloudinaryService.uploadImage(File(_selectedImage!.path));
          if (imageUrl != null) {
            profilePicUrl = imageUrl;
          }
        }

        // Update user profile
        final updatedUser = UserModel(
          uid: _user!.uid,
          name: _nameController.text.trim(),
          email: _user!.email,
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          profilePicUrl: profilePicUrl,
          rating: _user!.rating,
          ratingCount: _user!.ratingCount,
        );

        await _databaseService.updateUser(updatedUser);

        setState(() {
          _user = updatedUser;
          _isEditing = false;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'User not found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current user ID: ${_authService.currentUser?.uid ?? "Not logged in"}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadUserProfile,
                            child: const Text('Retry Loading Profile'),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Profile Header with Enhanced Design
                        SliverAppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          pinned: true,
                          expandedHeight: 220,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF0D47A1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Background Pattern
                                  Positioned(
                                    top: -50,
                                    right: -50,
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -30,
                                    left: -30,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ),

                                  // Content
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 60),

                                      // Enhanced Profile Picture with Animation
                                      TweenAnimationBuilder(
                                        duration: const Duration(milliseconds: 800),
                                        tween: Tween<double>(begin: 0, end: 1),
                                        builder: (context, double value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: Opacity(
                                              opacity: value,
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 4),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.3),
                                                          blurRadius: 15,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: CircleAvatar(
                                                      radius: 55,
                                                      backgroundColor: Colors.white,
                                                      backgroundImage: _selectedImage != null
                                                          ? FileImage(File(_selectedImage!.path))
                                                          : _user!.profilePicUrl != null
                                                              ? NetworkImage(_user!.profilePicUrl!)
                                                              : null,
                                                      child: _user!.profilePicUrl == null && _selectedImage == null
                                                          ? Container(
                                                              decoration: const BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                ),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons.person,
                                                                size: 55,
                                                                color: Colors.white,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                  if (_isEditing)
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: const Color(0xFF2196F3), width: 3),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.2),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(Icons.camera_alt, color: Color(0xFF2196F3), size: 20),
                                                          onPressed: _pickImage,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      // Enhanced User Info with Animation
                                      TweenAnimationBuilder(
                                        duration: const Duration(milliseconds: 1000),
                                        tween: Tween<double>(begin: 0, end: 1),
                                        builder: (context, double value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(0, 20 * (1 - value)),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    _user!.name,
                                                    style: const TextStyle(
                                                      fontSize: 26,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black26,
                                                          offset: Offset(0, 2),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      _user!.email,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_user!.ratingCount > 0) ...[
                                                    const SizedBox(height: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(25),
                                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.star, color: Colors.amber, size: 18),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            '${_user!.rating.toStringAsFixed(1)} (${_user!.ratingCount} reviews)',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            if (!_isEditing)
                              Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                ),
                              ),
                            if (_isEditing)
                              Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _selectedImage = null;
                                      // Reset text controllers
                                      _nameController.text = _user!.name;
                                      _phoneController.text = _user!.phone;
                                      _locationController.text = _user!.location;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),

                        // Enhanced Statistics Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [Colors.white, Colors.grey.shade50],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Your Statistics',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF232B38),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                _buildAnimatedStatItem('Items Listed', _itemsListed.toString(), Icons.inventory, Colors.blue),
                                                _buildAnimatedStatItem('Items Rented', _itemsRented.toString(), Icons.shopping_cart, Colors.green),
                                                _buildAnimatedStatItem('Earnings', '₹${_totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.orange),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Edit Form or Profile Info
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: _isEditing ? _buildEditForm() : _buildProfileInfo(),
                          ),
                        ),

        // Settings Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF232B38),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSettingsCard(),
                                const SizedBox(height: 24),
                                const Text(
                                  'My Items',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF232B38),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMyItemsCard(),
                              ],
                            ),
                          ),
                        ),

                        // Logout Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 1400),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double animationValue, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - animationValue)),
                                  child: Opacity(
                                    opacity: animationValue,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.red, Color(0xFFD32F2F)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.logout, color: Colors.white),
                                        ),
                                        title: const Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: const Text('Sign out of your account'),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onTap: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Logout'),
                                              content: const Text('Are you sure you want to logout?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: const Text('Logout'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            await _authService.signOut();
                                            if (!mounted) return;
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                              (route) => false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Bottom spacing
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 32),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildAnimatedStatItem(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232B38),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF232B38),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _selectedImage = null;
                        // Reset text controllers
                        _nameController.text = _user!.name;
                        _phoneController.text = _user!.phone;
                        _locationController.text = _user!.location;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone, color: Color(0xFF2196F3)),
            ),
            title: const Text(
              'Phone',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF232B38),
              ),
            ),
            subtitle: Text(
              _user!.phone,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF2196F3)),
            ),
            title: const Text(
              'Location',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF232B38),
              ),
            ),
            subtitle: Text(
              _user!.location,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.email, color: Color(0xFF2196F3)),
            ),
            title: const Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF232B38),
              ),
            ),
            subtitle: Text(
              _user!.email,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyItemsCard() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.inventory, color: Colors.white),
                    ),
                    title: const Text(
                      'My Items',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232B38),
                      ),
                    ),
                    subtitle: const Text('View and manage your listed items'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyItemsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_circle, color: Colors.white),
                    ),
                    title: const Text(
                      'Add New Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232B38),
                      ),
                    ),
                    subtitle: const Text('List a new item for rent'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddItemScreen()),
                      );
                      // Refresh user data if needed
                      _loadUserProfile();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  _buildAnimatedSettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications settings coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildAnimatedSettingsTile(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Control your privacy settings',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy settings coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildAnimatedSettingsTile(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildAnimatedSettingsTile(
                    icon: Icons.info,
                    title: 'About',
                    subtitle: 'App version and information',
                    color: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('About page coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF232B38),
                ),
              ),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}
