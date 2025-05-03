import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/settings_provider.dart';
import '../../state/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _photoFile;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    _nameController = TextEditingController(text: settingsProvider.doctorName);
    _specialtyController = TextEditingController(
      text: settingsProvider.specialty,
    );
    _phoneController = TextEditingController(
      text: settingsProvider.phoneNumber,
    );
    _emailController = TextEditingController(text: settingsProvider.email);
    _addressController = TextEditingController(text: settingsProvider.address);
    _notesController = TextEditingController(text: settingsProvider.notes);
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _photoFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      final settings = {
        'doctorName': _nameController.text,
        'specialty': _specialtyController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'notes': _notesController.text,
      };

      if (_photoFile != null) {
        // TODO: Upload photo and get URL
        // settings['profilePhotoUrl'] = uploadedPhotoUrl;
      }

      final success = await settingsProvider.updateSettings(settings);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: LoadingAnimation())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo Section
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                backgroundImage:
                                    _photoFile != null
                                        ? FileImage(_photoFile!)
                                        : settingsProvider
                                            .profilePhotoUrl
                                            .isNotEmpty
                                        ? NetworkImage(
                                          settingsProvider.profilePhotoUrl,
                                        )
                                        : null,
                                child:
                                    _photoFile == null &&
                                            settingsProvider
                                                .profilePhotoUrl
                                                .isEmpty
                                        ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppTheme.primaryColor,
                                        )
                                        : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Information Section
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Email'),
                                subtitle: Text(
                                  authProvider.currentUser?.email ?? '',
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Subscription'),
                                subtitle: Text(
                                  authProvider.subscriptionEndDateString,
                                ),
                                trailing:
                                    authProvider.isSubscriptionActive
                                        ? Chip(
                                          label: const Text('Active'),
                                          backgroundColor: Colors.green
                                              .withOpacity(0.2),
                                        )
                                        : Chip(
                                          label: const Text('Expired'),
                                          backgroundColor: Colors.red
                                              .withOpacity(0.2),
                                        ),
                              ),
                              if (authProvider.isSubscriptionActive)
                                ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: const Text('Days Remaining'),
                                  subtitle: Text(
                                    '${authProvider.daysUntilSubscriptionExpires} days',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Professional Information Section
                      Text(
                        'Professional Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Doctor Name',
                        controller: _nameController,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Specialty',
                        controller: _specialtyController,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.medical_services),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your specialty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Contact Information Section
                      Text(
                        'Contact Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Address',
                        controller: _addressController,
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      const SizedBox(height: 32),

                      // Additional Information Section
                      Text(
                        'Additional Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Notes',
                        controller: _notesController,
                        maxLines: 4,
                        prefixIcon: const Icon(Icons.note),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      CustomButton(
                        label: 'Save Settings',
                        onPressed: _saveSettings,
                        isFullWidth: true,
                        icon: Icons.save,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
