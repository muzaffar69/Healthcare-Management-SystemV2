import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/user_model.dart';
import '../../common/widgets/sidebar_navigation.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../common/widgets/patient_card.dart';
import '../../common/animations/page_transitions.dart';
import '../../state/auth_provider.dart';
import '../../state/patient_provider.dart';
import 'add_patient_screen.dart';
import 'patient_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isOnline = true;
  String _searchQuery = '';
  
  List<Patient> _filteredPatients = [];
  List<Patient> _pinnedPatients = [];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _searchController.addListener(_onSearchChanged);
    
    // Check connectivity
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
    
    // Load patients
    _loadPatients();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterPatients();
    });
  }
  
  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      await patientProvider.loadPatients();
      
      setState(() {
        _filterPatients();
        _isLoading = false;
      });
      
      // Start the animation
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error dialog
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }
  
  void _filterPatients() {
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final allPatients = patientProvider.patients;
    
    if (_searchQuery.isEmpty) {
      // When not searching, show all patients
      _filteredPatients = allPatients.where((p) => !p.isPinned).toList();
      _pinnedPatients = allPatients.where((p) => p.isPinned).toList();
    } else {
      // When searching, filter by name or phone
      final query = _searchQuery.toLowerCase();
      _filteredPatients = allPatients.where((p) => 
        (p.name.toLowerCase().contains(query) || 
         p.phoneNumber.contains(query)) && 
        !p.isPinned
      ).toList();
      
      _pinnedPatients = allPatients.where((p) => 
        (p.name.toLowerCase().contains(query) || 
         p.phoneNumber.contains(query)) && 
        p.isPinned
      ).toList();
    }
  }
  
  Future<void> _togglePatientPin(Patient patient, bool isPinned) async {
    try {
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      await patientProvider.togglePatientPin(patient.id, isPinned);
      
      // Update the filtered lists
      setState(() {
        _filterPatients();
      });
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update patient: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
  
  void _navigateToPatientDetails(Patient patient) {
    Navigator.of(context).push(
      HeroPageRoute(
        page: PatientDetailsScreen(patient: patient),
        settings: RouteSettings(name: AppRoutes.patientDetails),
      ),
    );
  }
  
  void _navigateToAddPatient() {
    Navigator.of(context).push(
      SlidePageRoute(
        page: const AddPatientScreen(),
        direction: SlideDirection.up,
        settings: RouteSettings(name: AppRoutes.addPatient),
      ),
    ).then((_) => _loadPatients());
  }
  
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }
  
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Get current user
    final User? currentUser = authProvider.currentUser;
    
    // Check if we're in a wide screen layout
    final bool isWideScreen = mediaQuery.size.width > 1200;
    final bool isTabletScreen = mediaQuery.size.width > 800 && mediaQuery.size.width <= 1200;
    
    // Calculate the number of columns for the grid
    int crossAxisCount = 1;
    if (isWideScreen) {
      crossAxisCount = 3;
    } else if (isTabletScreen) {
      crossAxisCount = 2;
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sidebar Navigation
                SidebarNavigation(
                  user: currentUser,
                  currentRoute: AppRoutes.home,
                  onLogout: _handleLogout,
                ),
                
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // App Bar
                      _buildAppBar(theme, currentUser),
                      
                      // Connectivity Warning
                      if (!_isOnline)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: AppTheme.warning.withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wifi_off,
                                color: AppTheme.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppConstants.errorNoInternet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Patient List
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: LoadingAnimation(
                                  message: 'Loading patients...',
                                ),
                              )
                            : _buildPatientList(theme, crossAxisCount),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      
      // Add Patient FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPatient,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add new patient',
        heroTag: 'add_patient_fab',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildAppBar(ThemeData theme, User currentUser) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      child: Row(
        children: [
          // Welcome Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              Text(
                currentUser.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Search Box
          Container(
            width: 300,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Add Patient Button
          CustomButton(
            label: 'Add New Patient',
            icon: Icons.add,
            onPressed: _navigateToAddPatient,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPatientList(ThemeData theme, int crossAxisCount) {
    if (_pinnedPatients.isEmpty && _filteredPatients.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Patients Section
            if (_pinnedPatients.isNotEmpty) ...[
              Text(
                'Pinned Patients',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pinnedPatients.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final patient = _pinnedPatients[index];
                    return Container(
                      width: 300,
                      child: PatientCard(
                        patient: patient,
                        onTap: _navigateToPatientDetails,
                        onPinToggle: _togglePatientPin,
                        compact: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // All Patients Section
            Text(
              _searchQuery.isEmpty ? 'All Patients' : 'Search Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Showing results for "${_searchQuery}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Grid of Patient Cards
            Expanded(
              child: _filteredPatients.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No patients found. Add a new patient to get started.'
                            : 'No patients matching "${_searchQuery}"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _filteredPatients[index];
                        return PatientCard(
                          patient: patient,
                          onTap: _navigateToPatientDetails,
                          onPinToggle: _togglePatientPin,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'No patients found'
                  : 'No patients matching "${_searchQuery}"',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first patient to get started'
                  : 'Try a different search term',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_searchQuery.isEmpty)
              CustomButton(
                label: 'Add New Patient',
                icon: Icons.add,
                onPressed: _navigateToAddPatient,
                type: ButtonType.primary,
              ),
          ],
        ),
      ),
    );
  }
}
