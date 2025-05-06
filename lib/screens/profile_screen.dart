import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopspot/cubit/auth_cubit/auth_state.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/models/user_model.dart';
import 'package:shopspot/cubit/auth_cubit/auth_cubit.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/widgets/custom_button.dart';
import 'package:shopspot/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _gender;
  String? _level;
  File? _profileImage;

  bool _isEditing = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _nameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();

    // Retrieve user profile when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final authCubit = context.read<AuthCubit>();
    final connectivityService = context.read<ConnectivityService>();

    // Check if we need to get fresh data from server
    final shouldLoadFromServer =
        connectivityService.isOnline && connectivityService.shouldRefresh;

    // Display current cached data immediately if available
    _updateUIWithUserData(authCubit.user);

    if (shouldLoadFromServer) {
      // Load from server
      await authCubit.getProfile(context);

      // Update UI with fresh data
      _updateUIWithUserData(authCubit.user);

      // Mark as refreshed
      connectivityService.markRefreshed();
    } else if (!connectivityService.isOnline) {
      // Show toast if we're offline
      Fluttertoast.showToast(
        msg: "You are offline. Showing cached profile data.",
        backgroundColor: Colors.red,
      );
    }
  }

  void _updateUIWithUserData(User? user) {
    if (user == null) return;

    setState(() {
      _nameController.text = user.name;
      _gender = user.gender;
      _level = user.level;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: source);

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unable to access camera or gallery. Please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt, size: 40),
                    ),
                    const Text('Camera'),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library, size: 40),
                    ),
                    const Text('Gallery'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _nameError = null;
      _passwordError = null;
      _confirmPasswordError = null;

      // Validate name (required)
      if (_nameController.text.isEmpty) {
        _nameError = 'Name is required';
        isValid = false;
      }

      // Only validate password fields if they're not empty (optional on profile update)
      if (_passwordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty) {
        // Validate password
        if (_passwordController.text.length < 8 ||
            !RegExp(r'\d').hasMatch(_passwordController.text)) {
          _passwordError =
              'Password must be at least 8 characters with at least 1 number';
          isValid = false;
        }

        // Validate confirm password
        if (_passwordController.text != _confirmPasswordController.text) {
          _confirmPasswordError = 'Passwords do not match';
          isValid = false;
        }
      }
    });

    return isValid;
  }

  Future<void> _updateProfile() async {
    if (!_validateInputs()) return;

    final authCubit = context.read<AuthCubit>();

    final success = await authCubit.updateProfile(
      name: _nameController.text,
      gender: _gender,
      level: _level,
      password:
          _passwordController.text.isEmpty ? null : _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text.isEmpty
          ? null
          : _confirmPasswordController.text,
      profilePhoto: _profileImage,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: "Profile updated successfully",
        backgroundColor: Colors.green,
      );

      setState(() {
        _isEditing = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } else {
      Fluttertoast.showToast(
        msg: authCubit.state is AuthError
            ? (authCubit.state as AuthError).message
            : "Something went wrong. Please try again.",
        backgroundColor: Colors.orange,
      );
    }
  }

  Future<void> _logout() async {
    final authCubit = context.read<AuthCubit>();
    await authCubit.logout(context);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;

                if (!_isEditing) {
                  // Reset form if canceling edit
                  _updateUIWithUserData(user);
                  // Reset profile image when canceling to show the original image
                  _profileImage = null;
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.restaurant),
            tooltip: 'Restaurants',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: authCubit.state is AuthLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture
                    _buildProfilePicture(user),

                    const SizedBox(height: 30),

                    // User Information
                    _isEditing ? _buildEditForm() : _buildProfileInfo(user),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture(User user) {
    // If using a local file (newly selected image)
    final hasLocalFile = _profileImage != null;

    // If user has a locally cached file
    final hasLocalCachedFile = !hasLocalFile &&
        user.profilePhoto != null &&
        user.profilePhoto!.isNotEmpty;

    return Stack(
      children: [
        // Choose the appropriate image display method based on the image source
        if (hasLocalFile || hasLocalCachedFile)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: ClipOval(
              child: Image(
                image: hasLocalFile
                    ? FileImage(_profileImage!)
                    : FileImage(File(user.profilePhoto!)),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 70, color: Colors.grey);
                },
              ),
            ),
          )
        else
          // Default avatar when no image is available
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 70, color: Colors.grey),
          ),

        // Edit button (remains unchanged)
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _showImagePickerOptions,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(User user) {
    return Column(
      children: [
        _buildInfoCard('Name', user.name),
        _buildInfoCard('Email', user.email),
        if (user.gender != null) _buildInfoCard('Gender', user.gender!),
        if (user.level != null) _buildInfoCard('Level', user.level!),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name field
        CustomTextField(
          controller: _nameController,
          labelText: 'Name',
          errorText: _nameError,
        ),

        // Gender radio buttons
        _buildGenderSelection(),

        // Level dropdown
        _buildLevelDropdown(),

        // Password fields
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password (Optional)',
              errorText: _passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            obscureText: !_showPassword,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              errorText: _confirmPasswordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            obscureText: !_showConfirmPassword,
          ),
        ),

        const SizedBox(height: 20),

        // Update button
        CustomButton(
          text: 'Update Profile',
          onPressed: _updateProfile,
          isLoading: context.read<AuthCubit>().state is AuthLoading,
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Level',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        value: _level,
        hint: const Text('Select level'),
        items: ['1', '2', '3', '4'].map((String level) {
          return DropdownMenuItem<String>(
            value: level,
            child: Text('Level $level'),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _level = value;
          });
        },
      ),
    );
  }
}
