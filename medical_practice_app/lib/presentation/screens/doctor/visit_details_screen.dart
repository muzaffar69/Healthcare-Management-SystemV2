import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/visit_model.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/models/lab_test_model.dart';
import '../../../core/services/pdf_service.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/visit_provider.dart';
import '../../state/auth_provider.dart';

class VisitDetailsScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;
  
  const VisitDetailsScreen({
    Key? key,
    required this.patient,
    required this.visit,
  }) : super(key: key);

  @override
  _VisitDetailsScreenState createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _notesController;
  
  List<Prescription> _prescriptions = [];
  List<Prescription> _selectedPrescriptions = [];
  List<LabTest> _labTests = [];
  List<LabTest> _selectedLabTests = [];
  
  String _searchPrescriptionQuery = '';
  String _searchLabTestQuery = '';
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSendingPrescriptions = false;
  bool _isSendingLabTests = false;
  bool _isGeneratingPdf = false;
  
  List<String> _availableDrugs = [];
  List<String> _availableLabTests = [];
  
  bool _hasPharmacyAccess = false;
  bool _hasLabAccess = false;
  
  final _drugNameController = TextEditingController();
  final _drugNoteController = TextEditingController();
  final _labTestNameController = TextEditingController();
  final _labTestNoteController = TextEditingController();
  
  final _pdfService = PDFService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesController = TextEditingController(text: widget.visit.notes);
    
    // Initialize prescriptions and lab tests
    _prescriptions = List.from(widget.visit.prescriptions);
    _labTests = List.from(widget.visit.labTests);
    
    // Initialize PDF service
    _initializePdfService();
    
    // Load drugs and lab tests
    _loadDrugsAndLabTests();
    
    // Check account access
    _checkAccountAccess();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _drugNameController.dispose();
    _drugNoteController.dispose();
    _labTestNameController.dispose();
    _labTestNoteController.dispose();
    super.dispose();
  }
  
  Future<void> _initializePdfService() async {
    try {
      await _pdfService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize PDF service: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadDrugsAndLabTests() async {
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      
      // Load drugs
      final drugs = await visitProvider.getDrugs();
      
      // Load lab tests
      final labTests = await visitProvider.getLabTestTypes();
      
      if (mounted) {
        setState(() {
          _availableDrugs = drugs;
          _availableLabTests = labTests;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load drugs and lab tests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _checkAccountAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _hasPharmacyAccess = authProvider.hasPharmacyAccess;
      _hasLabAccess = authProvider.hasLabAccess;
    });
  }
  
  Future<void> _saveVisit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      
      // Update the visit with the new data
      final notes = _notesController.text;
      
      await visitProvider.updateVisit(
        visit: widget.visit.copyWith(
          notes: notes,
          prescriptions: _prescriptions,
          labTests: _labTests,
        ),
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visit: ${e.toString()}'),
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
  
  Future<void> _sendPrescriptionsToPharmacy() async {
    // Check if no prescriptions are selected
    if (_selectedPrescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one prescription to send'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if all selected prescriptions are already sent
    final unsent = _selectedPrescriptions.where((p) => !p.sentToPharmacy).toList();
    if (unsent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All selected prescriptions have already been sent'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Confirm sending
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to Pharmacy'),
        content: Text(
          'Are you sure you want to send ${unsent.length} prescription(s) to the pharmacy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      return;
    }
    
    if (mounted) {
      setState(() {
        _isSendingPrescriptions = true;
      });
    }
    
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      
      // Generate PDF
      await _generatePrescriptionPdf();
      
      // Send to pharmacy
      await visitProvider.sendPrescriptionsToPharmacy(
        visitId: widget.visit.id,
        prescriptions: unsent,
      );
      
      // Update prescriptions list
      setState(() {
        _prescriptions = _prescriptions.map((p) {
          if (_selectedPrescriptions.any((s) => s.id == p.id)) {
            return p.copyWith(sentToPharmacy: true);
          }
          return p;
        }).toList();
        
        _selectedPrescriptions = [];
      });
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescriptions sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send prescriptions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPrescriptions = false;
        });
      }
    }
  }
  
  Future<void> _sendLabTestsToLab() async {
    // Check if no lab tests are selected
    if (_selectedLabTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one lab test to send'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if all selected lab tests are already sent
    final unsent = _selectedLabTests.where((lt) => !lt.sentToLab).toList();
    if (unsent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All selected lab tests have already been sent'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Confirm sending
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to Laboratory'),
        content: Text(
          'Are you sure you want to send ${unsent.length} lab test(s) to the laboratory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      return;
    }
    
    if (mounted) {
      setState(() {
        _isSendingLabTests = true;
      });
    }
    
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      
      // Generate PDF
      await _generateLabOrderPdf();
      
      // Send to laboratory
      await visitProvider.sendLabTestsToLab(
        visitId: widget.visit.id,
        labTests: unsent,
      );
      
      // Update lab tests list
      setState(() {
        _labTests = _labTests.map((lt) {
          if (_selectedLabTests.any((s) => s.id == lt.id)) {
            return lt.copyWith(sentToLab: true);
          }
          return lt;
        }).toList();
        
        _selectedLabTests = [];
      });
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab tests sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send lab tests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLabTests = false;
        });
      }
    }
  }
  
  Future<void> _generatePrescriptionPdf() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      setState(() {
        _isGeneratingPdf = true;
      });
      
      // Generate PDF
      final pdfFile = await _pdfService.generatePrescriptionPDF(
        visit: widget.visit,
        patient: widget.patient,
        doctor: user,
        prescriptions: _selectedPrescriptions,
      );
      
      // Share PDF
      await _pdfService.sharePDF(pdfFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }
  
  Future<void> _generateLabOrderPdf() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      setState(() {
        _isGeneratingPdf = true;
      });
      
      // Generate PDF
      final pdfFile = await _pdfService.generateLabOrderPDF(
        visit: widget.visit,
        patient: widget.patient,
        doctor: user,
        labTests: _selectedLabTests,
      );
      
      // Share PDF
      await _pdfService.sharePDF(pdfFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }
  
  void _addPrescription() {
    // Show dialog to add prescription
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _availableDrugs;
                }
                return _availableDrugs.where((drug) => 
                  drug.toLowerCase().contains(textEditingValue.text.toLowerCase())
                ).toList();
              },
              onSelected: (String selection) {
                _drugNameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _drugNameController.text = controller.text;
                return CustomTextField(
                  label: 'Drug Name',
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (value) => onFieldSubmitted(),
                  isRequired: true,
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Notes',
              controller: _drugNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _drugNameController.clear();
              _drugNoteController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final drugName = _drugNameController.text;
              final note = _drugNoteController.text;
              
              if (drugName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a drug name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create a new prescription
              final prescription = Prescription(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                visitId: widget.visit.id,
                drugName: drugName,
                notes: note,
                lastModified: DateTime.now(),
              );
              
              // Add to the list
              setState(() {
                _prescriptions.add(prescription);
              });
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Clear the controllers
              _drugNameController.clear();
              _drugNoteController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _addLabTest() {
    // Show dialog to add lab test
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Lab Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _availableLabTests;
                }
                return _availableLabTests.where((test) => 
                  test.toLowerCase().contains(textEditingValue.text.toLowerCase())
                ).toList();
              },
              onSelected: (String selection) {
                _labTestNameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _labTestNameController.text = controller.text;
                return CustomTextField(
                  label: 'Test Name',
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (value) => onFieldSubmitted(),
                  isRequired: true,
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Notes',
              controller: _labTestNoteController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _labTestNameController.clear();
              _labTestNoteController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final testName = _labTestNameController.text;
              final note = _labTestNoteController.text;
              
              if (testName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a test name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create a new lab test
              final labTest = LabTest(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                visitId: widget.visit.id,
                testName: testName,
                notes: note,
                lastModified: DateTime.now(),
              );
              
              // Add to the list
              setState(() {
                _labTests.add(labTest);
              });
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Clear the controllers
              _labTestNameController.clear();
              _labTestNoteController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _removePrescription(Prescription prescription) {
    // Confirm removal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Prescription'),
        content: Text('Are you sure you want to remove "${prescription.drugName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove from the lists
              setState(() {
                _prescriptions.removeWhere((p) => p.id == prescription.id);
                _selectedPrescriptions.removeWhere((p) => p.id == prescription.id);
              });
              
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  void _removeLabTest(LabTest labTest) {
    // Confirm removal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Lab Test'),
        content: Text('Are you sure you want to remove "${labTest.testName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove from the lists
              setState(() {
                _labTests.removeWhere((lt) => lt.id == labTest.id);
                _selectedLabTests.removeWhere((lt) => lt.id == labTest.id);
              });
              
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  void _togglePrescriptionSelection(Prescription prescription) {
    setState(() {
      if (_selectedPrescriptions.any((p) => p.id == prescription.id)) {
        _selectedPrescriptions.removeWhere((p) => p.id == prescription.id);
      } else {
        _selectedPrescriptions.add(prescription);
      }
    });
  }
  
  void _toggleLabTestSelection(LabTest labTest) {
    setState(() {
      if (_selectedLabTests.any((lt) => lt.id == labTest.id)) {
        _selectedLabTests.removeWhere((lt) => lt.id == labTest.id);
      } else {
        _selectedLabTests.add(labTest);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Visit #${widget.visit.visitNumber}'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Visit',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _isLoading ? null : _saveVisit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                        _notesController.text = widget.visit.notes;
                        _prescriptions = List.from(widget.visit.prescriptions);
                        _labTests = List.from(widget.visit.labTests);
                        _selectedPrescriptions = [];
                        _selectedLabTests = [];
                      });
                    },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Visit Info'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Lab Tests'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: LoadingAnimation(message: 'Saving changes...'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisitInfoTab(theme),
                _buildPrescriptionsTab(theme),
                _buildLabTestsTab(theme),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget? _buildFloatingActionButton() {
    if (_isLoading || _isSendingPrescriptions || _isSendingLabTests || _isGeneratingPdf) {
      return null;
    }
    
    if (_tabController.index == 1 && _isEditing) {
      return FloatingActionButton(
        onPressed: _addPrescription,
        tooltip: 'Add Prescription',
        child: const Icon(Icons.add),
      );
    }
    
    if (_tabController.index == 2 && _isEditing) {
      return FloatingActionButton(
        onPressed: _addLabTest,
        tooltip: 'Add Lab Test',
        child: const Icon(Icons.add),
      );
    }
    
    return null;
  }
  
  Widget _buildVisitInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visit header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visit #${widget.visit.visitNumber}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(widget.visit.visitDate),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Patient',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: widget.patient.photoUrl.isNotEmpty
                            ? NetworkImage(widget.patient.photoUrl)
                            : null,
                        child: widget.patient.photoUrl.isEmpty
                            ? Text(
                                widget.patient.name.isNotEmpty
                                    ? widget.patient.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.patient.age} years, ${widget.patient.gender}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Visit notes
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                      ? CustomTextField(
                          label: 'Notes',
                          controller: _notesController,
                          maxLines: 5,
                        )
                      : widget.visit.notes.isNotEmpty
                          ? Text(widget.visit.notes)
                          : Text(
                              'No notes for this visit',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          theme,
                          Icons.medication,
                          'Prescriptions',
                          _prescriptions.length.toString(),
                          _prescriptions.any((p) => p.sentToPharmacy)
                              ? '${_prescriptions.where((p) => p.sentToPharmacy).length} sent'
                              : 'None sent',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          theme,
                          Icons.science,
                          'Lab Tests',
                          _labTests.length.toString(),
                          _labTests.any((lt) => lt.sentToLab)
                              ? '${_labTests.where((lt) => lt.sentToLab).length} sent'
                              : 'None sent',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrescriptionsTab(ThemeData theme) {
    final filteredPrescriptions = _searchPrescriptionQuery.isEmpty
        ? _prescriptions
        : _prescriptions.where((p) => 
            p.drugName.toLowerCase().contains(_searchPrescriptionQuery.toLowerCase()) ||
            p.notes.toLowerCase().contains(_searchPrescriptionQuery.toLowerCase())
          ).toList();
    
    return Column(
      children: [
        // Action bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search and actions row
              Row(
                children: [
                  // Search box
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchPrescriptionQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search prescriptions...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Generate PDF button
                  if (!_isEditing && _selectedPrescriptions.isNotEmpty)
                    CustomButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: _isGeneratingPdf ? null : _generatePrescriptionPdf,
                      isLoading: _isGeneratingPdf,
                      type: ButtonType.secondary,
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Send to Pharmacy button
                  if (_hasPharmacyAccess && !_isEditing && _selectedPrescriptions.isNotEmpty)
                    CustomButton(
                      label: 'Send',
                      icon: Icons.send,
                      onPressed: _isSendingPrescriptions ? null : _sendPrescriptionsToPharmacy,
                      isLoading: _isSendingPrescriptions,
                    ),
                ],
              ),
              
              // Selection info
              if (_selectedPrescriptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_selectedPrescriptions.length} prescription(s) selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPrescriptions = [];
                        });
                      },
                      child: const Text('Clear selection'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Prescriptions list
        Expanded(
          child: filteredPrescriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 80,
                        color: theme.colorScheme.onBackground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchPrescriptionQuery.isEmpty
                            ? 'No prescriptions yet'
                            : 'No prescriptions matching "${_searchPrescriptionQuery}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchPrescriptionQuery.isEmpty)
                        Text(
                          _isEditing
                              ? 'Add a prescription using the + button'
                              : 'No prescriptions were added for this visit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredPrescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = filteredPrescriptions[index];
                    return _buildPrescriptionCard(theme, prescription);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildLabTestsTab(ThemeData theme) {
    final filteredLabTests = _searchLabTestQuery.isEmpty
        ? _labTests
        : _labTests.where((lt) => 
            lt.testName.toLowerCase().contains(_searchLabTestQuery.toLowerCase()) ||
            lt.notes.toLowerCase().contains(_searchLabTestQuery.toLowerCase())
          ).toList();
    
    return Column(
      children: [
        // Action bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search and actions row
              Row(
                children: [
                  // Search box
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchLabTestQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search lab tests...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Generate PDF button
                  if (!_isEditing && _selectedLabTests.isNotEmpty)
                    CustomButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: _isGeneratingPdf ? null : _generateLabOrderPdf,
                      isLoading: _isGeneratingPdf,
                      type: ButtonType.secondary,
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Send to Lab button
                  if (_hasLabAccess && !_isEditing && _selectedLabTests.isNotEmpty)
                    CustomButton(
                      label: 'Send',
                      icon: Icons.send,
                      onPressed: _isSendingLabTests ? null : _sendLabTestsToLab,
                      isLoading: _isSendingLabTests,
                    ),
                ],
              ),
              
              // Selection info
              if (_selectedLabTests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_selectedLabTests.length} lab test(s) selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLabTests = [];
                        });
                      },
                      child: const Text('Clear selection'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Lab tests list
        Expanded(
          child: filteredLabTests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 80,
                        color: theme.colorScheme.onBackground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchLabTestQuery.isEmpty
                            ? 'No lab tests yet'
                            : 'No lab tests matching "${_searchLabTestQuery}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchLabTestQuery.isEmpty)
                        Text(
                          _isEditing
                              ? 'Add a lab test using the + button'
                              : 'No lab tests were ordered for this visit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredLabTests.length,
                  itemBuilder: (context, index) {
                    final labTest = filteredLabTests[index];
                    return _buildLabTestCard(theme, labTest);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem(
    ThemeData theme,
    IconData icon,
    String title,
    String count,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onBackground.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrescriptionCard(ThemeData theme, Prescription prescription) {
    final isSelected = _selectedPrescriptions.any((p) => p.id == prescription.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isEditing
            ? null
            : () => _togglePrescriptionSelection(prescription),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _togglePrescriptionSelection(prescription);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              
              // Prescription content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prescription.drugName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            tooltip: 'Remove',
                            onPressed: () => _removePrescription(prescription),
                          ),
                      ],
                    ),
                    if (prescription.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        prescription.notes,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(prescription.statusColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prescription.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Color(prescription.statusColor),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          prescription.timeElapsed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLabTestCard(ThemeData theme, LabTest labTest) {
    final isSelected = _selectedLabTests.any((lt) => lt.id == labTest.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isEditing
            ? null
            : () => _toggleLabTestSelection(labTest),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleLabTestSelection(labTest);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              
              // Lab test content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            labTest.testName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            tooltip: 'Remove',
                            onPressed: () => _removeLabTest(labTest),
                          ),
                      ],
                    ),
                    if (labTest.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        labTest.notes,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(labTest.statusColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            labTest.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Color(labTest.statusColor),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          labTest.timeElapsed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    if (labTest.hasResults) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            labTest.isResultImage ? Icons.image : Icons.picture_as_pdf,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Results',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
