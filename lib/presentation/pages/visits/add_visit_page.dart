import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/visit_model.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/models/lab_order_model.dart';
import '../../../data/models/drug_model.dart';
import '../../../data/models/lab_test_model.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class AddVisitPage extends StatefulWidget {
  final Patient patient;

  const AddVisitPage({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}   

class _AddVisitPageState extends State<AddVisitPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  DoctorSettings? _doctorSettings;
  List<Drug> _drugs = [];
  List<LabTest> _labTests = [];
  List<Prescription> _prescriptions = [];
  List<LabOrder> _labOrders = [];
  
  // Form controllers
  final _visitDetailsController = TextEditingController();
  
  // Date picker
  DateTime _selectedDate = DateTime.now();
  
  // Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _visitDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load drugs and lab tests
      _drugs = await DatabaseHelper.instance.readAllDrugs();
      _labTests = await DatabaseHelper.instance.readAllLabTests();
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, add some mock data
      _drugs = [
        Drug(id: 1, name: 'Paracetamol'),
        Drug(id: 2, name: 'Ibuprofen'),
        Drug(id: 3, name: 'Aspirin'),
      ];
      
      _labTests = [
        LabTest(id: 1, name: 'Complete Blood Count (CBC)'),
        LabTest(id: 2, name: 'Blood Glucose Test'),
        LabTest(id: 3, name: 'Lipid Panel'),
      ];
      
      _doctorSettings = DoctorSettings(
        id: 1,
        name: 'Dr. Alex Wilson',
        specialty: 'Cardiologist',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addPrescription() async {
    // Show dialog to select drug and add prescription
    await showDialog(
      context: context,
      builder: (context) => _buildAddPrescriptionDialog(),
    );
  }

  void _addLabOrder() async {
    // Show dialog to select lab test and add order
    await showDialog(
      context: context,
      builder: (context) => _buildAddLabOrderDialog(),
    );
  }

  void _deletePrescription(int index) {
    setState(() {
      _prescriptions.removeAt(index);
    });
  }

  void _deleteLabOrder(int index) {
    setState(() {
      _labOrders.removeAt(index);
    });
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Create new visit
      final newVisit = Visit(
        patientId: widget.patient.id!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        details: _visitDetailsController.text,
      );
      
      // Save visit to database
      final visitId = await DatabaseHelper.instance.createVisit(newVisit);
      
      // Save prescriptions
      for (var prescription in _prescriptions) {
        final newPrescription = Prescription(
          visitId: visitId,
          drugId: prescription.drugId,
          drugName: prescription.drugName,
          note: prescription.note,
        );
        
        await DatabaseHelper.instance.createPrescription(newPrescription);
      }
      
      // Save lab orders
      for (var labOrder in _labOrders) {
        final newLabOrder = LabOrder(
          visitId: visitId,
          labTestId: labOrder.labTestId,
          testName: labOrder.testName,
          note: labOrder.note,
        );
        
        await DatabaseHelper.instance.createLabOrder(newLabOrder);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to the previous screen
      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving visit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add visit: $e'),
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
        Navigator.of(context).pushReplacementNamed('/settings');
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
            selectedIndex: -1, // No sidebar item is selected on this page
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVisitDetailsTab(),
                _buildPrescriptionsTab(),
                _buildLabOrdersTab(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeAnimation(
      delay: 0.2,
      child: Row(
        children: [
          BackButton(
            color: AppTheme.textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Visit',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.patient.name,
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.patient.age} years, ${widget.patient.gender}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return FadeAnimation(
      delay: 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Visit Details'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Lab Tests'),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDetailsTab() {
    return FadeAnimation(
      delay: 0.4,
      child: Form(
        key: _formKey,
        child: Card(
          elevation: 5,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visit Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Visit Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextFormField(
                    controller: _visitDetailsController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter visit details, symptoms, diagnosis, etc.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter visit details';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    AnimatedButton(
                      onPressed: () => _tabController.animateTo(1),
                      color: AppTheme.primaryColor,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Continue to Prescriptions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    return FadeAnimation(
      delay: 0.4,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescriptions (${_prescriptions.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              AnimatedButton(
                onPressed: _addPrescription,
                color: AppTheme.secondaryColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Prescription',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _prescriptions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.medication,
                    message: 'No prescriptions added yet',
                    actionLabel: 'Add Prescription',
                    onAction: _addPrescription,
                  )
                : ListView.builder(
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.medication,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      prescription.drugName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    onPressed: () => _deletePrescription(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'Notes:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                prescription.note,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              AnimatedButton(
                onPressed: () => _tabController.animateTo(2),
                color: AppTheme.primaryColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Continue to Lab Tests',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabOrdersTab() {
    return FadeAnimation(
      delay: 0.4,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lab Tests (${_labOrders.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              AnimatedButton(
                onPressed: _addLabOrder,
                color: AppTheme.secondaryColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Lab Test',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _labOrders.isEmpty
                ? _buildEmptyState(
                    icon: Icons.science,
                    message: 'No lab tests added yet',
                    actionLabel: 'Add Lab Test',
                    onAction: _addLabOrder,
                  )
                : ListView.builder(
                    itemCount: _labOrders.length,
                    itemBuilder: (context, index) {
                      final labOrder = _labOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.science,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      labOrder.testName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteLabOrder(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'Notes:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                labOrder.note,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Prescriptions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 70,
            color: AppTheme.textLightColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textLightColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedButton(
            onPressed: onAction,
            color: AppTheme.secondaryColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          color: Colors.grey,
        ),
        const SizedBox(width: 20),
        AnimatedButton(
          onPressed: () => _saveVisit(),
          color: AppTheme.secondaryColor,
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
                  'Save Visit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAddPrescriptionDialog() {
    final drugController = TextEditingController();
    final noteController = TextEditingController();
    Drug? selectedDrug;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Add Prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Drug>(
                decoration: const InputDecoration(
                  labelText: 'Select Medication',
                  border: OutlineInputBorder(),
                ),
                items: _drugs.map((drug) {
                  return DropdownMenuItem<Drug>(
                    value: drug,
                    child: Text(drug.name),
                  );
                }).toList(),
                onChanged: (Drug? value) {
                  setState(() {
                    selectedDrug = value;
                    if (value != null) {
                      drugController.text = value.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Instructions/Notes',
                  hintText: 'Enter dosage, frequency, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedDrug == null || noteController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a medication and enter instructions'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _prescriptions.add(
                    Prescription(
                      visitId: 0, // Temporary, will be updated when saving
                      drugId: selectedDrug!.id!,
                      drugName: selectedDrug!.name,
                      note: noteController.text.trim(),
                    ),
                  );
                });

                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddLabOrderDialog() {
    final testController = TextEditingController();
    final noteController = TextEditingController();
    LabTest? selectedTest;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Add Lab Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LabTest>(
                decoration: const InputDecoration(
                  labelText: 'Select Lab Test',
                  border: OutlineInputBorder(),
                ),
                items: _labTests.map((test) {
                  return DropdownMenuItem<LabTest>(
                    value: test,
                    child: Text(test.name),
                  );
                }).toList(),
                onChanged: (LabTest? value) {
                  setState(() {
                    selectedTest = value;
                    if (value != null) {
                      testController.text = value.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Enter additional instructions or information',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedTest == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a lab test'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _labOrders.add(
                    LabOrder(
                      visitId: 0, // Temporary, will be updated when saving
                      labTestId: selectedTest!.id!,
                      testName: selectedTest!.name,
                      note: noteController.text.trim(),
                    ),
                  );
                });

                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}