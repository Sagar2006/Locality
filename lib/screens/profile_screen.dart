import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/services/cloudinary_service.dart';
import 'package:locality/services/database_service.dart';
import 'package:locality/screens/auth/login_screen.dart';

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
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final user = await _databaseService.getUser(currentUser.uid);
      setState(() {
        _user = user;
        
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && _user != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
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
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(child: Text('User not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Picture
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _selectedImage != null
                                    ? FileImage(File(_selectedImage!.path))
                                    : _user!.profilePicUrl != null
                                        ? NetworkImage(_user!.profilePicUrl!)
                                        : null,
                                child: _user!.profilePicUrl == null && _selectedImage == null
                                    ? const Icon(Icons.person, size: 60)
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    radius: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // User Info / Edit Form
                          _isEditing
                              ? Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Name',
                                          border: OutlineInputBorder(),
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
                                        decoration: const InputDecoration(
                                          labelText: 'Phone',
                                          border: OutlineInputBorder(),
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
                                        decoration: const InputDecoration(
                                          labelText: 'Location',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your location';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          OutlinedButton(
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
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: _isSaving ? null : _saveProfile,
                                            child: _isSaving
                                                ? const CircularProgressIndicator()
                                                : const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Name
                                    Text(
                                      _user!.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Email
                                    Text(
                                      _user!.email,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Rating
                                    if (_user!.ratingCount > 0)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_user!.rating.toStringAsFixed(1)} (${_user!.ratingCount} ratings)',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    
                                    const Divider(height: 40),
                                    
                                    // Contact Info
                                    ListTile(
                                      leading: const Icon(Icons.phone),
                                      title: const Text('Phone'),
                                      subtitle: Text(_user!.phone),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Location'),
                                      subtitle: Text(_user!.location),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Logout Button
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await _authService.signOut();
                                        if (!mounted) return;
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Logout'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
    );
  }
}
