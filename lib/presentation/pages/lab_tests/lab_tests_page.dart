import 'package:flutter/material.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/search_bar_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/lab_test_model.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class LabTestsPage extends StatefulWidget {
  const LabTestsPage({Key? key}) : super(key: key);

  @override
  State<LabTestsPage> createState() => _LabTestsPageState();
}

class _LabTestsPageState extends State<LabTestsPage> {
  final _searchController = TextEditingController();
  List<LabTest> _labTests = [];
  List<LabTest> _filteredLabTests = [];
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  LabTest? _editingLabTest;
  final _labTestNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _searchController.addListener(() {
      _filterLabTests(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _labTestNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load lab tests
      _labTests = await DatabaseHelper.instance.readAllLabTests();
      _filteredLabTests = List.from(_labTests);
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, add some mock data
      _labTests = [
        LabTest(id: 1, name: 'Complete Blood Count (CBC)'),
        LabTest(id: 2, name: 'Blood Glucose Test'),
        LabTest(id: 3, name: 'Lipid Panel'),
        LabTest(id: 4, name: 'Liver Function Test'),
        LabTest(id: 5, name: 'Urinalysis'),
      ];
      _filteredLabTests = List.from(_labTests);
      
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

  void _filterLabTests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLabTests = List.from(_labTests);
      } else {
        _filteredLabTests = _labTests
            .where((test) => test.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addLabTest() async {
    _labTestNameController.clear();
    _editingLabTest = null;
    _showLabTestDialog(isEditing: false);
  }

  Future<void> _editLabTest(LabTest labTest) async {
    _labTestNameController.text = labTest.name;
    _editingLabTest = labTest;
    _showLabTestDialog(isEditing: true);
  }

  Future<void> _deleteLabTest(LabTest labTest) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${labTest.name}"?'),
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
        await DatabaseHelper.instance.deleteLabTest(labTest.id!);
        _loadData(); // Reload data after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${labTest.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting lab test: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete lab test'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLabTestDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Lab Test' : 'Add New Lab Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labTestNameController,
              decoration: const InputDecoration(
                labelText: 'Lab Test Name',
                hintText: 'Enter lab test name',
              ),
              autofocus: true,
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
              final name = _labTestNameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              try {
                if (isEditing && _editingLabTest != null) {
                  // Update existing lab test
                  final updatedLabTest = LabTest(
                    id: _editingLabTest!.id,
                    name: name,
                  );
                  await DatabaseHelper.instance.updateLabTest(updatedLabTest);
                } else {
                  // Add new lab test
                  final newLabTest = LabTest(name: name);
                  await DatabaseHelper.instance.createLabTest(newLabTest);
                }

                Navigator.of(context).pop();
                _loadData(); // Reload data after adding/editing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing ? 'Lab test updated successfully' : 'Lab test added successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error saving lab test: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save lab test'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
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
        // Already on lab tests page
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
            selectedIndex: 3,
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildSearchAndAddSection(),
          const SizedBox(height: 20),
          _buildLabTestsList(),
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
            'Laboratory Tests Management',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add, edit, or remove laboratory tests from your database',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddSection() {
    return FadeAnimation(
      delay: 0.3,
      child: Row(
        children: [
          AnimatedSearchBar(
            controller: _searchController,
            hintText: 'Search lab tests...',
            onChanged: _filterLabTests,
            onSubmitted: (_) {},
          ),
          const Spacer(),
          AnimatedButton(
            onPressed: _addLabTest,
            color: AppTheme.secondaryColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Add New Lab Test',
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
    );
  }

  Widget _buildLabTestsList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredLabTests.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.science,
                size: 70,
                color: AppTheme.textLightColor.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isEmpty
                    ? 'No lab tests in the database yet'
                    : 'No lab tests matching "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textLightColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isEmpty)
                AnimatedButton(
                  onPressed: _addLabTest,
                  color: AppTheme.secondaryColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Your First Lab Test',
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
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ListView.separated(
            itemCount: _filteredLabTests.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final labTest = _filteredLabTests[index];
              return FadeAnimation(
                delay: 0.05 * index,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    labTest.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () => _editLabTest(labTest),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.warningColor,
                        ),
                        onPressed: () => _deleteLabTest(labTest),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}