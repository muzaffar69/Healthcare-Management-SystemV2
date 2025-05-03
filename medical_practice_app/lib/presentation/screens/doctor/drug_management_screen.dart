import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/visit_provider.dart';

class DrugManagementScreen extends StatefulWidget {
  const DrugManagementScreen({Key? key}) : super(key: key);

  @override
  _DrugManagementScreenState createState() => _DrugManagementScreenState();
}

class _DrugManagementScreenState extends State<DrugManagementScreen> {
  final _searchController = TextEditingController();
  final _addDrugController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrugs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _addDrugController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadDrugs() async {
    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      await visitProvider.getDrugs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load drugs: ${e.toString()}'),
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

  Future<void> _addDrug() async {
    final drugName = _addDrugController.text.trim();
    if (drugName.isEmpty) {
      return;
    }

    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final success = await visitProvider.addDrug(drugName);

      if (success && mounted) {
        _addDrugController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drug added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add drug: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDrug(String drugName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Drug'),
            content: Text('Are you sure you want to delete "$drugName"?'),
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
      final success = await visitProvider.deleteDrug(drugName);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drug deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete drug: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDrugDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Drug'),
            content: CustomTextField(
              label: 'Drug Name',
              controller: _addDrugController,
              placeholder: 'Enter drug name',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addDrugController.clear();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addDrug();
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
        title: const Text('Drug Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDrugDialog,
            tooltip: 'Add Drug',
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
              label: 'Search Drugs',
              placeholder: 'Enter drug name',
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

          // Drug list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingAnimation())
                    : Consumer<VisitProvider>(
                      builder: (context, visitProvider, child) {
                        final drugs =
                            visitProvider.drugs.where((drug) {
                              return drug.toLowerCase().contains(_searchQuery);
                            }).toList();

                        if (drugs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No drugs added yet'
                                      : 'No drugs matching your search',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_searchQuery.isEmpty)
                                  Text(
                                    'Add drugs using the + button',
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
                          itemCount: drugs.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final drug = drugs[index];
                            return ListTile(
                              title: Text(drug),
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
                                    onPressed: () => _deleteDrug(drug),
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
