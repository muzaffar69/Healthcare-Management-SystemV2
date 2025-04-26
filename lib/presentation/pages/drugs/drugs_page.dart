import 'package:flutter/material.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/search_bar_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/drug_model.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class DrugsPage extends StatefulWidget {
  const DrugsPage({Key? key}) : super(key: key);

  @override
  State<DrugsPage> createState() => _DrugsPageState();
}

class _DrugsPageState extends State<DrugsPage> {
  final _searchController = TextEditingController();
  List<Drug> _drugs = [];
  List<Drug> _filteredDrugs = [];
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  Drug? _editingDrug;
  final _drugNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _searchController.addListener(() {
      _filterDrugs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _drugNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load drugs
      _drugs = await DatabaseHelper.instance.readAllDrugs();
      _filteredDrugs = List.from(_drugs);
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, add some mock data
      _drugs = [
        Drug(id: 1, name: 'Paracetamol'),
        Drug(id: 2, name: 'Ibuprofen'),
        Drug(id: 3, name: 'Aspirin'),
        Drug(id: 4, name: 'Amoxicillin'),
        Drug(id: 5, name: 'Omeprazole'),
      ];
      _filteredDrugs = List.from(_drugs);
      
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

  void _filterDrugs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrugs = List.from(_drugs);
      } else {
        _filteredDrugs = _drugs
            .where((drug) => drug.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addDrug() async {
    _drugNameController.clear();
    _editingDrug = null;
    _showDrugDialog(isEditing: false);
  }

  Future<void> _editDrug(Drug drug) async {
    _drugNameController.text = drug.name;
    _editingDrug = drug;
    _showDrugDialog(isEditing: true);
  }

  Future<void> _deleteDrug(Drug drug) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${drug.name}"?'),
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
        await DatabaseHelper.instance.deleteDrug(drug.id!);
        _loadData(); // Reload data after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${drug.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting drug: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete drug'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDrugDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Drug' : 'Add New Drug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _drugNameController,
              decoration: const InputDecoration(
                labelText: 'Drug Name',
                hintText: 'Enter drug name',
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
              final name = _drugNameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              try {
                if (isEditing && _editingDrug != null) {
                  // Update existing drug
                  final updatedDrug = Drug(
                    id: _editingDrug!.id,
                    name: name,
                  );
                  await DatabaseHelper.instance.updateDrug(updatedDrug);
                } else {
                  // Add new drug
                  final newDrug = Drug(name: name);
                  await DatabaseHelper.instance.createDrug(newDrug);
                }

                Navigator.of(context).pop();
                _loadData(); // Reload data after adding/editing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing ? 'Drug updated successfully' : 'Drug added successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error saving drug: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save drug'),
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
        // Already on drugs page
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
            selectedIndex: 2,
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
          _buildDrugsList(),
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
            'Drugs Management',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add, edit, or remove medications from your database',
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
            hintText: 'Search drugs...',
            onChanged: _filterDrugs,
            onSubmitted: (_) {},
          ),
          const Spacer(),
          AnimatedButton(
            onPressed: _addDrug,
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
                  'Add New Drug',
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

  Widget _buildDrugsList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredDrugs.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medication,
                size: 70,
                color: AppTheme.textLightColor.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isEmpty
                    ? 'No drugs in the database yet'
                    : 'No drugs matching "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textLightColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isEmpty)
                AnimatedButton(
                  onPressed: _addDrug,
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
                        'Add Your First Drug',
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
            itemCount: _filteredDrugs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final drug = _filteredDrugs[index];
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
                      Icons.medication,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    drug.name,
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
                        onPressed: () => _editDrug(drug),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.warningColor,
                        ),
                        onPressed: () => _deleteDrug(drug),
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