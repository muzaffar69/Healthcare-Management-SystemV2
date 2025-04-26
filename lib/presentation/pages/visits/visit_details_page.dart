import 'package:flutter/material.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../../core/utils/pdf_generator.dart';
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

class VisitDetailsPage extends StatefulWidget {
  final Patient patient;
  final Visit visit;

  const VisitDetailsPage({
    Key? key,
    required this.patient,
    required this.visit,
  }) : super(key: key);

  @override
  State<VisitDetailsPage> createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  List<Drug> _drugs = [];
  List<LabTest> _labTests = [];
  List<Prescription> _prescriptions = [];
  List<LabOrder> _labOrders = [];
  
  // Controllers for editing visit details
  final _visitDetailsController = TextEditingController();
  bool _isEditingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _visitDetailsController.text = widget.visit.details;
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
      
      // Load prescriptions and lab orders for this visit
      if (widget.visit.id != null) {
        _prescriptions = await DatabaseHelper.instance.readVisitPrescriptions(widget.visit.id!);
        _labOrders = await DatabaseHelper.instance.readVisitLabOrders(widget.visit.id!);
      }
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
      
      // Example prescriptions and lab orders
      _prescriptions = [
        Prescription(
          id: 1,
          visitId: widget.visit.id ?? 1,
          drugId: 1,
          drugName: 'Paracetamol',
          note: 'Take 1 tablet every 6 hours as needed for pain.',
        ),
      ];
      
      _labOrders = [
        LabOrder(
          id: 1,
          visitId: widget.visit.id ?? 1,
          labTestId: 1,
          testName: 'Complete Blood Count (CBC)',
          note: 'Check for anemia and infection.',
        ),
      ];
      
      _doctorSettings = DoctorSettings(
        id: 1,
        name: 'Dr. Alex Wilson',
        specialty: 'Cardiologist',
        phoneNumber: '555-123-4567',
        email: 'dr.wilson@example.com',
        address: '123 Medical Center Dr, Healthville',
      );
    }

    setState(() {
      _isLoading = false;
    });
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

  void _saveVisitDetails() async {
    if (_isEditingDetails) {
      // Save updated details
      final updatedVisit = widget.visit.copyWith(
        details: _visitDetailsController.text,
      );
      
      try {
        await DatabaseHelper.instance.updateVisit(updatedVisit);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error updating visit details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update visit details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {
      _isEditingDetails = !_isEditingDetails;
    });
  }

  void _addPrescription() async {
    // Show dialog to select drug and add prescription
    await showDialog(
      context: context,
      builder: (context) => _buildAddPrescriptionDialog(),
    );
    
    // Reload prescriptions
    _loadData();
  }

  void _addLabOrder() async {
    // Show dialog to select lab test and add order
    await showDialog(
      context: context,
      builder: (context) => _buildAddLabOrderDialog(),
    );
    
    // Reload lab orders
    _loadData();
  }

  void _deletePrescription(Prescription prescription) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the prescription for "${prescription.drugName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DatabaseHelper.instance.deletePrescription(prescription.id!);
        _loadData(); // Reload data after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescription for ${prescription.drugName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting prescription: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete prescription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteLabOrder(LabOrder labOrder) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the lab order for "${labOrder.testName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DatabaseHelper.instance.deleteLabOrder(labOrder.id!);
        _loadData(); // Reload data after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lab order for ${labOrder.testName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting lab order: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete lab order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePrescriptionPDF() async {
    if (_doctorSettings == null || _prescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot generate prescription - missing data or no prescriptions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      String filePath = await PdfGenerator.generatePrescription(
        patient: widget.patient,
        prescriptions: _prescriptions,
        visitDate: widget.visit.date,
        visitDetails: widget.visit.details,
        doctorSettings: _doctorSettings!,
      );
      
      // Open the generated PDF
      await PdfGenerator.openPdf(filePath);
      
      // Update prescriptions to mark them as sent to pharmacy
      for (var prescription in _prescriptions) {
        if (!prescription.sentToPharmacy) {
          final updatedPrescription = prescription.copyWith(sentToPharmacy: true);
          await DatabaseHelper.instance.updatePrescription(updatedPrescription);
        }
      }
      
      // Reload prescriptions to update UI
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate prescription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateLabOrderPDF() async {
    if (_doctorSettings == null || _labOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot generate lab order - missing data or no lab tests'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      String filePath = await PdfGenerator.generateLabOrder(
        patient: widget.patient,
        labOrders: _labOrders,
        visitDate: widget.visit.date,
        visitDetails: widget.visit.details,
        doctorSettings: _doctorSettings!,
      );
      
      // Open the generated PDF
      await PdfGenerator.openPdf(filePath);
      
      // Update lab orders to mark them as sent to lab
      for (var labOrder in _labOrders) {
        if (!labOrder.sentToLab) {
          final updatedLabOrder = labOrder.copyWith(sentToLab: true);
          await DatabaseHelper.instance.updateLabOrder(updatedLabOrder);
        }
      }
      
      // Reload lab orders to update UI
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lab order generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating lab order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate lab order'),
          backgroundColor: Colors.red,
        ),
      );
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
              Row(
                children: [
                  const Text(
                    'Visit Details',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.visit.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.patient.name,
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 24,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Visit Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveVisitDetails,
                    icon: Icon(
                      _isEditingDetails ? Icons.save : Icons.edit,
                      size: 16,
                    ),
                    label: Text(_isEditingDetails ? 'Save' : 'Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditingDetails
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLightColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.visit.date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
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
                child: _isEditingDetails
                    ? TextField(
                        controller: _visitDetailsController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter visit details, symptoms, diagnosis, etc.',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            widget.visit.details,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
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
              Row(
                children: [
                  if (_prescriptions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: AnimatedButton(
                        onPressed: _generatePrescriptionPDF,
                        color: AppTheme.primaryColor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generate PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _prescriptions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.medication,
                    message: 'No prescriptions for this visit',
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prescription.drugName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                        if (prescription.sentToPharmacy) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: AppTheme.secondaryColor,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'Sent to pharmacy',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.secondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    onPressed: () => _deletePrescription(prescription),
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
                'Laboratory Tests (${_labOrders.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              Row(
                children: [
                  if (_labOrders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: AnimatedButton(
                        onPressed: _generateLabOrderPDF,
                        color: AppTheme.primaryColor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generate PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _labOrders.isEmpty
                ? _buildEmptyState(
                    icon: Icons.science,
                    message: 'No laboratory tests for this visit',
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          labOrder.testName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                        if (labOrder.sentToLab) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: AppTheme.secondaryColor,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'Sent to laboratory',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.secondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteLabOrder(labOrder),
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
              onPressed: () async {
                if (selectedDrug == null || noteController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a medication and enter instructions'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final newPrescription = Prescription(
                    visitId: widget.visit.id!,
                    drugId: selectedDrug!.id!,
                    drugName: selectedDrug!.name,
                    note: noteController.text.trim(),
                  );
                  
                  await DatabaseHelper.instance.createPrescription(newPrescription);
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prescription added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error saving prescription: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add prescription'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
              onPressed: () async {
                if (selectedTest == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a lab test'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final newLabOrder = LabOrder(
                    visitId: widget.visit.id!,
                    labTestId: selectedTest!.id!,
                    testName: selectedTest!.name,
                    note: noteController.text.trim(),
                  );
                  
                  await DatabaseHelper.instance.createLabOrder(newLabOrder);
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lab test added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error saving lab order: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add lab test'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}