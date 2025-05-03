import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/models/patient_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../common/widgets/patient_card.dart';
import '../../state/patient_provider.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Patient> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterPatients();
    });
  }

  Future<void> _loadPatients() async {
    try {
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      await patientProvider.loadPatients();
      _filterPatients();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patients: ${e.toString()}'),
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

  void _filterPatients() {
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );
    final allPatients = patientProvider.patients;

    if (_searchQuery.isEmpty) {
      _filteredPatients = allPatients;
    } else {
      _filteredPatients = patientProvider.searchPatients(_searchQuery);
    }
  }

  void _navigateToPatientDetails(Patient patient) {
    Navigator.pushNamed(context, AppRoutes.patientDetails, arguments: patient);
  }

  void _navigateToAddPatient() {
    Navigator.pushNamed(
      context,
      AppRoutes.addPatient,
    ).then((_) => _loadPatients());
  }

  Future<void> _togglePatientPin(Patient patient, bool isPinned) async {
    try {
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      await patientProvider.togglePatientPin(patient.id, isPinned);
      _filterPatients();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update patient: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddPatient,
            tooltip: 'Add Patient',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search Patients',
              placeholder: 'Enter name or phone number',
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

          // Patient List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingAnimation())
                    : _filteredPatients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No patients found'
                                : 'No patients matching your search',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Add patients using the + button',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadPatients,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: PatientCard(
                              patient: patient,
                              onTap: _navigateToPatientDetails,
                              onPinToggle: _togglePatientPin,
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
