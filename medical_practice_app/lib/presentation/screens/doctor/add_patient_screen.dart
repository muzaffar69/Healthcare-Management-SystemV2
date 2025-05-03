import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/patient_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/patient_provider.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _photoFile;

  // Form fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'Male';
  DateTime _firstVisitDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _chronicDiseasesController.dispose();
    _familyHistoryController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstVisitDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _firstVisitDate) {
      setState(() {
        _firstVisitDate = picked;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse the form data
      final name = _nameController.text;
      final age = int.parse(_ageController.text);
      final phoneNumber = _phoneController.text;
      final address = _addressController.text;

      double? weight;
      if (_weightController.text.isNotEmpty) {
        weight = double.parse(_weightController.text);
      }

      double? height;
      if (_heightController.text.isNotEmpty) {
        height = double.parse(_heightController.text);
      }

      final chronicDiseases =
          _chronicDiseasesController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      final familyHistory = _familyHistoryController.text;
      final notes = _notesController.text;

      // Create the patient
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      await patientProvider.addPatient(
        name: name,
        age: age,
        gender: _gender,
        phoneNumber: phoneNumber,
        address: address,
        firstVisitDate: _firstVisitDate,
        weight: weight,
        height: height,
        chronicDiseases: chronicDiseases,
        familyHistory: familyHistory,
        notes: notes,
        photoFile: _photoFile,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add patient: ${e.toString()}'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Patient')),
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
                      // Photo section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            backgroundImage:
                                _photoFile != null
                                    ? FileImage(_photoFile!)
                                    : null,
                            child:
                                _photoFile == null
                                    ? const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: AppTheme.primaryColor,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _pickImage,
                          child: const Text('Add Photo'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Basic Information
                      Text(
                        'Basic Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Name',
                        controller: _nameController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter patient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Age',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _gender = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Address',
                        controller: _addressController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text(
                            'First Visit Date: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_firstVisitDate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Medical Information
                      Text(
                        'Medical Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Weight (kg)',
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'Height (cm)',
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Chronic Diseases',
                        controller: _chronicDiseasesController,
                        maxLines: 2,
                        helperText: 'Separate with commas',
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Family History',
                        controller: _familyHistoryController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Notes',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      CustomButton(
                        label: 'Save Patient',
                        onPressed: _savePatient,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
