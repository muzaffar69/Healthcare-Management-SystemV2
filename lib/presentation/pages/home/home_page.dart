import 'package:flutter/material.dart';
import '../../../core/animations/search_bar_animation.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../widgets/patient_card.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _searchController.addListener(() {
      _filterPatients(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load patients
      _patients = await DatabaseHelper.instance.readAllPatients();
      _filteredPatients = List.from(_patients);
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, let's add some mock data
      _patients = [
        Patient(
          id: 1,
          name: 'John Doe',
          age: 45,
          gender: 'Male',
          phoneNumber: '555-123-4567',
        ),
        Patient(
          id: 2,
          name: 'Jane Smith',
          age: 32,
          gender: 'Female',
          phoneNumber: '555-987-6543',
        ),
        Patient(
          id: 3,
          name: 'Robert Johnson',
          age: 58,
          gender: 'Male',
          phoneNumber: '555-456-7890',
        ),
        Patient(
          id: 4,
          name: 'Emily Davis',
          age: 27,
          gender: 'Female',
          phoneNumber: '555-789-0123',
        ),
        Patient(
          id: 5,
          name: 'Michael Brown',
          age: 41,
          gender: 'Male',
          phoneNumber: '555-234-5678',
        ),
      ];
      _filteredPatients = List.from(_patients);
      
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

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        _filteredPatients = _patients
            .where((patient) =>
                patient.name.toLowerCase().contains(query.toLowerCase()) ||
                patient.phoneNumber.contains(query))
            .toList();
      }
    });
  }

  void _navigateToPatientDetails(Patient patient) {
    Navigator.of(context).pushNamed(
      '/patient-details',
      arguments: patient,
    );
  }

  void _navigateToAddPatient() {
    Navigator.of(context).pushNamed('/add-patient');
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on home page
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
            selectedIndex: 0,
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
          _buildPatientsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeAnimation(
      delay: 0.2,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _doctorSettings?.name ?? 'Doctor',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 28,
                ),
              ),
            ],
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
            hintText: 'Search patients...',
            onChanged: _filterPatients,
            onSubmitted: (_) {},
          ),
          const Spacer(),
          AnimatedButton(
            onPressed: _navigateToAddPatient,
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
                  'Add New Patient',
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

  Widget _buildPatientsList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search,
                size: 70,
                color: AppTheme.textLightColor.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isEmpty
                    ? 'No patients yet'
                    : 'No patients matching "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textLightColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isEmpty)
                AnimatedButton(
                  onPressed: _navigateToAddPatient,
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
                        'Add Your First Patient',
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
      child: ListView.builder(
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return PatientCard(
            patient: patient,
            onTap: () => _navigateToPatientDetails(patient),
            index: index,
          );
        },
      ),
    );
  }
}