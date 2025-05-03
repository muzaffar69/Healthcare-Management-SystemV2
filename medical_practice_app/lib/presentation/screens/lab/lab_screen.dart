import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/lab_test_model.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/visit_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/visit_provider.dart';
import '../../state/auth_provider.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({Key? key}) : super(key: key);

  @override
  _LabScreenState createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _labTests = [];
  String _filter = 'pending'; // pending, completed, all

  @override
  void initState() {
    super.initState();
    _loadLabTests();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadLabTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to fetch lab tests for this laboratory
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _labTests = [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load lab tests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLabTests {
    var filtered = _labTests;

    // Apply status filter
    if (_filter == 'pending') {
      filtered =
          filtered
              .where((lt) => !(lt['labTest'] as LabTest).completedByLab)
              .toList();
    } else if (_filter == 'completed') {
      filtered =
          filtered
              .where((lt) => (lt['labTest'] as LabTest).completedByLab)
              .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((lt) {
            final labTest = lt['labTest'] as LabTest;
            final patient = lt['patient'] as Patient;
            final doctor = lt['doctor'] as String;

            return labTest.testName.toLowerCase().contains(_searchQuery) ||
                patient.name.toLowerCase().contains(_searchQuery) ||
                doctor.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    return filtered;
  }

  Future<void> _uploadResults(Map<String, dynamic> labTestData) async {
    final labTest = labTestData['labTest'] as LabTest;

    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Show confirmation dialog
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Upload Results'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File: ${result.files.single.name}'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Notes (optional)',
                      controller: _notesController,
                      maxLines: 3,
                      placeholder: 'Add any notes about the results',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Upload'),
                  ),
                ],
              ),
        );

        if (confirm == true) {
          setState(() => _isLoading = true);

          try {
            // TODO: Implement file upload and API call
            await Future.delayed(const Duration(seconds: 2));

            _notesController.clear();
            _loadLabTests();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Results uploaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            throw Exception('Failed to upload results: $e');
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratory Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLabTests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Search
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
                // Search bar
                CustomTextField(
                  controller: _searchController,
                  label: 'Search',
                  placeholder: 'Search by test, patient, or doctor',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                          : null,
                ),
                const SizedBox(height: 16),

                // Filter chips
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Pending'),
                      selected: _filter == 'pending',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'pending' : 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: _filter == 'completed',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'completed' : 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filter = 'all';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lab Tests List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingAnimation())
                    : _filteredLabTests.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No lab tests found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadLabTests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredLabTests.length,
                        itemBuilder: (context, index) {
                          final data = _filteredLabTests[index];
                          final labTest = data['labTest'] as LabTest;
                          final patient = data['patient'] as Patient;
                          final doctor = data['doctor'] as String;
                          final visitDate = data['visitDate'] as DateTime;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Doctor info
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.medical_services,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dr. $doctor',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),

                                  // Patient info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        child: Text(
                                          patient.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            Text(
                                              '${patient.age} years, ${patient.gender}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Lab test details
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          labTest.testName,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (labTest.notes.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            labTest.notes,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Results section
                                  if (labTest.completedByLab &&
                                      labTest.hasResults) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Results uploaded'),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              // TODO: View results
                                            },
                                            child: const Text('View'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Footer
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ordered on ${visitDate.day}/${visitDate.month}/${visitDate.year}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      if (!labTest.completedByLab)
                                        CustomButton(
                                          label: 'Upload Results',
                                          icon: Icons.upload_file,
                                          onPressed: () => _uploadResults(data),
                                          type: ButtonType.primary,
                                        )
                                      else
                                        Chip(
                                          label: const Text('Completed'),
                                          backgroundColor: Colors.green
                                              .withOpacity(0.2),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
