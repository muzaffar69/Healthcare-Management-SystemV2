
import 'package:flutter/material.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/slide_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/visit_model.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/datasources/database_helper.dart';

class PatientDetailsPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailsPage({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> with SingleTickerProviderStateMixin {
  List<Visit> _visits = [];
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load patient visits
      _visits = await DatabaseHelper.instance.readPatientVisits(widget.patient.id!);
    } catch (e) {
      // In a real app, handle errors appropriately
      print('Error loading data: $e');
      
      // For demonstration purposes, add some mock data
      _visits = [
        Visit(
          id: 1,
          patientId: widget.patient.id!,
          date: '2023-07-15',
          details: 'Regular checkup. Patient complains of mild headaches.',
        ),
        Visit(
          id: 2,
          patientId: widget.patient.id!,
          date: '2023-08-22',
          details: 'Follow-up for headaches. Symptoms have improved with medication.',
        ),
      ];
      
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

  void _addNewVisit() {
    Navigator.of(context).pushNamed(
      '/add-visit',
      arguments: widget.patient,
    ).then((_) {
      // Reload data when returning from add visit page
      _loadData();
    });
  }

  void _navigateToVisitDetails(Visit visit) {
    Navigator.of(context).pushNamed(
      '/visit-details',
      arguments: {
        'patient': widget.patient,
        'visit': visit,
      },
    ).then((_) {
      // Reload data when returning from visit details
      _loadData();
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
                _buildPatientInfoTab(),
                _buildVisitsTab(),
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
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.patient.name,
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 26,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedButton(
            onPressed: _addNewVisit,
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
                  'New Visit',
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
            Tab(text: 'Patient Information'),
            Tab(text: 'Visit History'),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoTab() {
    return FadeAnimation(
      delay: 0.4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientBasicInfo(),
            const SizedBox(height: 20),
            _buildPatientMedicalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientBasicInfo() {
    return Card(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientAvatar(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoField(
                              label: 'Full Name',
                              value: widget.patient.name,
                              icon: Icons.person,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoField(
                              label: 'Age',
                              value: '${widget.patient.age} years',
                              icon: Icons.cake,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoField(
                              label: 'Gender',
                              value: widget.patient.gender,
                              icon: widget.patient.gender.toLowerCase() == 'male'
                                  ? Icons.male
                                  : Icons.female,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoField(
                              label: 'Phone Number',
                              value: widget.patient.phoneNumber,
                              icon: Icons.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoField(
                              label: 'Address',
                              value: widget.patient.address ?? 'Not available',
                              icon: Icons.location_on,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoField(
                              label: 'First Visit',
                              value: widget.patient.firstVisitDate ?? 'Not available',
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientMedicalInfo() {
    return Card(
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
            const Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoField(
                    label: 'Height',
                    value: widget.patient.height != null
                        ? '${widget.patient.height} cm'
                        : 'Not available',
                    icon: Icons.height,
                  ),
                ),
                Expanded(
                  child: _buildInfoField(
                    label: 'Weight',
                    value: widget.patient.weight != null
                        ? '${widget.patient.weight} kg'
                        : 'Not available',
                    icon: Icons.fitness_center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildExpandableInfoField(
              label: 'Chronic Diseases',
              value: widget.patient.chronicDiseases ?? 'None',
              icon: Icons.medical_services,
            ),
            const SizedBox(height: 15),
            _buildExpandableInfoField(
              label: 'Family History',
              value: widget.patient.familyHistory ?? 'None',
              icon: Icons.family_restroom,
            ),
            const SizedBox(height: 15),
            _buildExpandableInfoField(
              label: 'Additional Notes',
              value: widget.patient.notes ?? 'None',
              icon: Icons.note,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
          backgroundImage: widget.patient.profilePicPath != null
              ? AssetImage(widget.patient.profilePicPath!)
              : null,
          child: widget.patient.profilePicPath == null
              ? Text(
                  widget.patient.name.isNotEmpty
                      ? widget.patient.name.substring(0, 1).toUpperCase()
                      : '',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement edit patient functionality
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            side: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return ExpansionTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textColor,
        ),
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitsTab() {
    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note,
              size: 70,
              color: AppTheme.textLightColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No visits recorded yet',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textLightColor,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedButton(
              onPressed: _addNewVisit,
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
                    'Record First Visit',
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

    return ListView.builder(
      itemCount: _visits.length,
      itemBuilder: (context, index) {
        final visit = _visits[index];
        return SlideAnimation(
          beginOffset: Offset(50, 0),
          child: Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () => _navigateToVisitDetails(visit),
              borderRadius: BorderRadius.circular(15),
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
                            Icons.event_note,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visit #${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Date: ${visit.date}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textLightColor,
                          ),
                          onPressed: () => _navigateToVisitDetails(visit),
                        ),
                      ],
                    ),
                    if (visit.details.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        visit.details,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (visit.prescriptions != null && visit.prescriptions!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.medication,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Prescriptions: ${visit.prescriptions!.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (visit.labOrders != null && visit.labOrders!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.science,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Lab Tests: ${visit.labOrders!.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}