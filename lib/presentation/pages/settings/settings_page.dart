import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  bool _isSaving = false;
  String? _profileImagePath;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form keys
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Set form values
      _nameController.text = _doctorSettings?.name ?? '';
      _specialtyController.text = _doctorSettings?.specialty ?? '';
      _phoneController.text = _doctorSettings?.phoneNumber ?? '';
      _emailController.text = _doctorSettings?.email ?? '';
      _addressController.text = _doctorSettings?.address ?? '';
      _notesController.text = _doctorSettings?.notes ?? '';
      _profileImagePath = _doctorSettings?.profilePicPath;
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, add some mock data
      _doctorSettings = DoctorSettings(
        id: 1,
        name: 'Dr. Alex Wilson',
        specialty: 'Cardiologist',
        phoneNumber: '555-123-4567',
        email: 'dr.wilson@example.com',
        address: '123 Medical Center Dr, Healthville',
      );
      
      // Set form values from mock data
      _nameController.text = _doctorSettings?.name ?? '';
      _specialtyController.text = _doctorSettings?.specialty ?? '';
      _phoneController.text = _doctorSettings?.phoneNumber ?? '';
      _emailController.text = _doctorSettings?.email ?? '';
      _addressController.text = _doctorSettings?.address ?? '';
      _notesController.text = _doctorSettings?.notes ?? '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedSettings = DoctorSettings(
        id: 1, // Doctor ID is always 1 in this app
        name: _nameController.text,
        specialty: _specialtyController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        notes: _notesController.text,
        profilePicPath: _profileImagePath,
      );
      
      await DatabaseHelper.instance.updateDoctorSettings(updatedSettings);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload data to reflect changes
      _loadData();
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/drugs');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/lab-tests');
        break;
      case 4:
        // Already on settings page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: 4,
            onItemSelected: _handleNavigation,
            doctorSettings: _doctorSettings,
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildSettingsForm(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeAnimation(
      delay: 0.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage your profile and application settings',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return FadeAnimation(
      delay: 0.3,
      child: Card(
        elevation: 5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImageSection(),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doctor Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildBasicInfoSection(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _buildContactInfoSection(),
                const SizedBox(height: 40),
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _buildNotesSection(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              image: _profileImagePath != null
                  ? DecorationImage(
                      image: FileImage(File(_profileImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image, size: 16),
          label: const Text('Change Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            side: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  prefixIcon: Icon(Icons.medical_services),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        prefixIcon: Icon(Icons.note),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: AnimatedButton(
        onPressed: () => _saveSettings(),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}