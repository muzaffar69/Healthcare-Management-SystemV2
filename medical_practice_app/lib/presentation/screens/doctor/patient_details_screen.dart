import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/visit_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../common/animations/page_transitions.dart';
import '../../state/patient_provider.dart';
import '../../state/visit_provider.dart';
import 'add_visit_screen.dart';
import 'visit_details_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  
  const PatientDetailsScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _familyHistoryController;
  late TextEditingController _notesController;
  
  String _gender = 'Male';
  bool _isEditing = false;
  bool _isLoading = false;
  bool _visitLoading = false;
  List<Visit> _visits = [];
  File? _photoFile;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize controllers with patient data
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phoneNumber);
    _addressController = TextEditingController(text: widget.patient.address);
    _weightController = TextEditingController(
      text: widget.patient.weight != null ? widget.patient.weight.toString() : ''
    );
    _heightController = TextEditingController(
      text: widget.patient.height != null ? widget.patient.height.toString() : ''
    );
    _chronicDiseasesController = TextEditingController(
      text: widget.patient.chronicDiseases.join(', ')
    );
    _familyHistoryController = TextEditingController(text: widget.patient.familyHistory);
    _notesController = TextEditingController(text: widget.patient.notes);
    
    _gender = widget.patient.gender;
    
    // Load patient visits
    _loadVisits();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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
  
  Future<void> _loadVisits() async {
    if (mounted) {
      setState(() {
        _visitLoading = true;
      });
    }
    
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final visits = await visitProvider.getVisits(widget.patient.id);
      
      if (mounted) {
        setState(() {
          _visits = visits;
          _visitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _visitLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load visits: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
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
      
      final chronicDiseases = _chronicDiseasesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final familyHistory = _familyHistoryController.text;
      final notes = _notesController.text;
      
      // Create updated patient object
      final updatedPatient = widget.patient.copyWith(
        name: name,
        age: age,
        gender: _gender,
        phoneNumber: phoneNumber,
        address: address,
        weight: weight,
        height: height,
        chronicDiseases: chronicDiseases,
        familyHistory: familyHistory,
        notes: notes,
      );
      
      // Update the patient
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      await patientProvider.updatePatient(
        id: updatedPatient.id,
        name: name,
        age: age,
        gender: _gender,
        phoneNumber: phoneNumber,
        address: address,
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
            content: Text('Patient updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update patient: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        _photoFile = File(pickedImage.path);
      });
    }
  }
  
  Future<void> _addNewVisit() async {
    // Navigate to the add visit screen
    Navigator.of(context).push(
      SlidePageRoute(
        page: AddVisitScreen(patient: widget.patient),
        direction: SlideDirection.up,
      ),
    ).then((_) {
      // Reload visits when returning from the add visit screen
      _loadVisits();
    });
  }
  
  void _viewVisitDetails(Visit visit) {
    // Navigate to the visit details screen
    Navigator.of(context).push(
      SlidePageRoute(
        page: VisitDetailsScreen(
          patient: widget.patient,
          visit: visit,
        ),
        direction: SlideDirection.left,
      ),
    ).then((_) {
      // Reload visits when returning from the visit details screen
      _loadVisits();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = widget.patient;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'Edit Patient',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _isLoading ? null : _savePatient,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.cancel),
              tooltip: 'Cancel',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                        
                        // Reset controllers to original values
                        _nameController.text = patient.name;
                        _ageController.text = patient.age.toString();
                        _phoneController.text = patient.phoneNumber;
                        _addressController.text = patient.address;
                        _weightController.text =
                            patient.weight != null ? patient.weight.toString() : '';
                        _heightController.text =
                            patient.height != null ? patient.height.toString() : '';
                        _chronicDiseasesController.text = patient.chronicDiseases.join(', ');
                        _familyHistoryController.text = patient.familyHistory;
                        _notesController.text = patient.notes;
                        
                        _gender = patient.gender;
                        _photoFile = null;
                      });
                    },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Patient Info'),
            Tab(text: 'Visits'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: LoadingAnimation(message: 'Saving changes...'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPatientInfoTab(theme),
                _buildVisitsTab(theme),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addNewVisit,
              tooltip: 'Add New Visit',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildPatientInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient photo and basic info
            _buildPatientHeader(theme),
            
            const SizedBox(height: 24),
            
            // Contact information
            _buildSectionHeader(theme, 'Contact Information'),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              isEnabled: _isEditing,
              isRequired: true,
              prefixIcon: const Icon(Icons.phone),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Address',
              controller: _addressController,
              keyboardType: TextInputType.streetAddress,
              isEnabled: _isEditing,
              prefixIcon: const Icon(Icons.location_on),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Medical information
            _buildSectionHeader(theme, 'Medical Information'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Weight (kg)',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    isEnabled: _isEditing,
                    prefixIcon: const Icon(Icons.monitor_weight),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    isEnabled: _isEditing,
                    prefixIcon: const Icon(Icons.height),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (widget.patient.weight != null && widget.patient.height != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BMI',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.patient.bmi?.toStringAsFixed(1) ?? 'N/A'}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.patient.bmiCategory,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _getBmiCategoryColor(widget.patient.bmiCategory),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            CustomTextField(
              label: 'Chronic Diseases',
              controller: _chronicDiseasesController,
              isEnabled: _isEditing,
              prefixIcon: const Icon(Icons.medical_services),
              helperText: 'Separate with commas',
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Family History',
              controller: _familyHistoryController,
              isEnabled: _isEditing,
              prefixIcon: const Icon(Icons.family_restroom),
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Additional notes
            _buildSectionHeader(theme, 'Additional Notes'),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Notes',
              controller: _notesController,
              isEnabled: _isEditing,
              prefixIcon: const Icon(Icons.note),
              maxLines: 5,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVisitsTab(ThemeData theme) {
    return _visitLoading
        ? Center(child: LoadingAnimation(message: 'Loading visits...'))
        : _visits.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 80,
                      color: theme.colorScheme.onBackground.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No visits yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a new visit to get started',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      label: 'Add New Visit',
                      icon: Icons.add,
                      onPressed: _addNewVisit,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _visits.length,
                itemBuilder: (context, index) {
                  final visit = _visits[index];
                  return _buildVisitCard(theme, visit);
                },
              );
  }
  
  Widget _buildPatientHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient photo
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          child: Hero(
            tag: 'patient_avatar_${widget.patient.id}',
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: _photoFile != null
                        ? DecorationImage(
                            image: FileImage(_photoFile!),
                            fit: BoxFit.cover,
                          )
                        : widget.patient.photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.patient.photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: widget.patient.photoUrl.isEmpty && _photoFile == null
                      ? Center(
                          child: Text(
                            widget.patient.name.isNotEmpty
                                ? widget.patient.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        )
                      : null,
                ),
                if (_isEditing)
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
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Basic info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing) ...[
                CustomTextField(
                  label: 'Name',
                  controller: _nameController,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
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
                            return 'Invalid';
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
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
              ] else ...[
                Text(
                  widget.patient.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '${widget.patient.age} years, ${widget.patient.gender}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'First visit: ${DateFormat('dd/MM/yyyy').format(widget.patient.firstVisitDate)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: theme.colorScheme.primary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVisitCard(ThemeData theme, Visit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewVisitDetails(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Visit #${visit.visitNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(visit.visitDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (visit.hasPrescriptions)
                        Tooltip(
                          message: 'Has prescriptions',
                          child: Icon(
                            Icons.medication,
                            color: visit.areAllPrescriptionsFulfilled
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                      if (visit.hasPrescriptions) const SizedBox(width: 8),
                      if (visit.hasLabTests)
                        Tooltip(
                          message: 'Has lab tests',
                          child: Icon(
                            Icons.science,
                            color: visit.areAllLabTestsCompleted
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (visit.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  visit.notes,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                visit.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getBmiCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.orange;
      case 'Normal weight':
        return Colors.green;
      case 'Overweight':
        return Colors.amber.shade700;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
