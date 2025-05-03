import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/visit_provider.dart';

class LabTestManagementScreen extends StatefulWidget {
  const LabTestManagementScreen({Key? key}) : super(key: key);

  @override
  _LabTestManagementScreenState createState() =>
      _LabTestManagementScreenState();
}

class _LabTestManagementScreenState extends State<LabTestManagementScreen> {
  final _searchController = TextEditingController();
  final _addTestController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

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
    _addTestController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadLabTests() async {
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      await visitProvider.getLabTestTypes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load lab tests: ${e.toString()}'),
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

  Future<void> _addLabTest() async {
    final testName = _addTestController.text.trim();
    if (testName.isEmpty) {
      return;
    }

    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final success = await visitProvider.addLabTestType(testName);

      if (success && mounted) {
        _addTestController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab test added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add lab test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLabTest(String testName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Lab Test'),
            content: Text('Are you sure you want to delete "$testName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final success = await visitProvider.deleteLabTestType(testName);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab test deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete lab test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddLabTestDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Lab Test'),
            content: CustomTextField(
              label: 'Test Name',
              controller: _addTestController,
              placeholder: 'Enter lab test name',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addTestController.clear();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addLabTest();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Test Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddLabTestDialog,
            tooltip: 'Add Lab Test',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search Lab Tests',
              placeholder: 'Enter lab test name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                      : null,
            ),
          ),

          // Lab test list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingAnimation())
                    : Consumer<VisitProvider>(
                      builder: (context, visitProvider, child) {
                        final labTests =
                            visitProvider.labTestTypes.where((test) {
                              return test.toLowerCase().contains(_searchQuery);
                            }).toList();

                        if (labTests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.science_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No lab tests added yet'
                                      : 'No lab tests matching your search',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_searchQuery.isEmpty)
                                  Text(
                                    'Add lab tests using the + button',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onBackground
                                          .withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: labTests.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final labTest = labTests[index];
                            return ListTile(
                              title: Text(labTest),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Implement edit functionality
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteLabTest(labTest),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
