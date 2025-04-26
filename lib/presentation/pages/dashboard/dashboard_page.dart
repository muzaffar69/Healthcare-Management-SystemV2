import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// ignore: depend_on_referenced_packages
import 'package:logging/logging.dart';
import '../../../core/animations/fade_animation.dart';
import '../../themes/app_theme.dart';
import '../../widgets/navigation_sidebar.dart';
import '../../../data/models/doctor_settings_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/visit_model.dart';
// ignore: unused_import
import '../../../data/models/prescription_model.dart';
// ignore: unused_import
import '../../../data/models/lab_order_model.dart';
import '../../../data/datasources/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static final _log = Logger('DashboardPage');
  bool _isLoading = true;
  DoctorSettings? _doctorSettings;
  
  // Statistics
  int _totalPatients = 0;
  int _totalVisits = 0;
  int _totalPrescriptions = 0;
  int _totalLabOrders = 0;
  
  // Recent data
  List<Patient> _recentPatients = [];
  List<Visit> _recentVisits = [];
  
  // Chart data
  List<Map<String, dynamic>> _visitsByMonth = [];
  List<Map<String, dynamic>> _prescriptionsByMonth = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor settings
      _doctorSettings = await DatabaseHelper.instance.readDoctorSettings();
      
      // Load statistics from database
      await _loadStatistics();
      
      // Load recent data
      await _loadRecentData();
      
      // Load chart data
      await _loadChartData();
    } catch (e) {
      _log.severe('Error loading data', e);
      
      // For demonstration purposes, add some mock data
      _totalPatients = 45;
      _totalVisits = 128;
      _totalPrescriptions = 96;
      _totalLabOrders = 52;
      
      _recentPatients = [
        Patient(id: 1, name: 'John Doe', age: 45, gender: 'Male', phoneNumber: '555-123-4567'),
        Patient(id: 2, name: 'Jane Smith', age: 32, gender: 'Female', phoneNumber: '555-987-6543'),
        Patient(id: 3, name: 'Robert Johnson', age: 58, gender: 'Male', phoneNumber: '555-456-7890'),
      ];
      
      _recentVisits = [
        Visit(id: 1, patientId: 1, date: '2023-11-05', details: 'Regular checkup'),
        Visit(id: 2, patientId: 2, date: '2023-11-03', details: 'Fever and cough'),
        Visit(id: 3, patientId: 3, date: '2023-11-01', details: 'Follow-up for hypertension'),
      ];
      
      _visitsByMonth = [
        {'month': 'Jan', 'count': 8},
        {'month': 'Feb', 'count': 10},
        {'month': 'Mar', 'count': 7},
        {'month': 'Apr', 'count': 12},
        {'month': 'May', 'count': 15},
        {'month': 'Jun', 'count': 9},
        {'month': 'Jul', 'count': 11},
        {'month': 'Aug', 'count': 13},
        {'month': 'Sep', 'count': 14},
        {'month': 'Oct', 'count': 16},
        {'month': 'Nov', 'count': 12},
        {'month': 'Dec', 'count': 0},
      ];
      
      _prescriptionsByMonth = [
        {'month': 'Jan', 'count': 6},
        {'month': 'Feb', 'count': 8},
        {'month': 'Mar', 'count': 5},
        {'month': 'Apr', 'count': 9},
        {'month': 'May', 'count': 12},
        {'month': 'Jun', 'count': 7},
        {'month': 'Jul', 'count': 8},
        {'month': 'Aug', 'count': 10},
        {'month': 'Sep', 'count': 11},
        {'month': 'Oct', 'count': 13},
        {'month': 'Nov', 'count': 9},
        {'month': 'Dec', 'count': 0},
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

  Future<void> _loadStatistics() async {
    // Get patients count
    final patients = await DatabaseHelper.instance.readAllPatients();
    _totalPatients = patients.length;
    
    // Get visits, prescriptions, and lab orders counts
    // In a real app, you'd create specific queries for these
    int visitCount = 0;
    int prescriptionCount = 0;
    int labOrderCount = 0;
    
    for (var patient in patients) {
      final visits = await DatabaseHelper.instance.readPatientVisits(patient.id!);
      visitCount += visits.length;
      
      for (var visit in visits) {
        if (visit.prescriptions != null) {
          prescriptionCount += visit.prescriptions!.length;
        }
        
        if (visit.labOrders != null) {
          labOrderCount += visit.labOrders!.length;
        }
      }
    }
    
    _totalVisits = visitCount;
    _totalPrescriptions = prescriptionCount;
    _totalLabOrders = labOrderCount;
  }

  Future<void> _loadRecentData() async {
    // Load recent patients (last 5)
    final patients = await DatabaseHelper.instance.readAllPatients();
    _recentPatients = patients.take(5).toList();
    
    // Load recent visits (last 5)
    List<Visit> allVisits = [];
    for (var patient in patients) {
      final visits = await DatabaseHelper.instance.readPatientVisits(patient.id!);
      for (var visit in visits) {
        // Add patient name to visit for display
        allVisits.add(visit);
      }
    }
    
    // Sort visits by date (descending)
    allVisits.sort((a, b) => b.date.compareTo(a.date));
    _recentVisits = allVisits.take(5).toList();
  }

  Future<void> _loadChartData() async {
    // For simplicity, we're using mock data
    // In a real app, you'd query the database to get visits and prescriptions by month
    _visitsByMonth = [
      {'month': 'Jan', 'count': 8},
      {'month': 'Feb', 'count': 10},
      {'month': 'Mar', 'count': 7},
      {'month': 'Apr', 'count': 12},
      {'month': 'May', 'count': 15},
      {'month': 'Jun', 'count': 9},
      {'month': 'Jul', 'count': 11},
      {'month': 'Aug', 'count': 13},
      {'month': 'Sep', 'count': 14},
      {'month': 'Oct', 'count': 16},
      {'month': 'Nov', 'count': 12},
      {'month': 'Dec', 'count': 0},
    ];
    
    _prescriptionsByMonth = [
      {'month': 'Jan', 'count': 6},
      {'month': 'Feb', 'count': 8},
      {'month': 'Mar', 'count': 5},
      {'month': 'Apr', 'count': 9},
      {'month': 'May', 'count': 12},
      {'month': 'Jun', 'count': 7},
      {'month': 'Jul', 'count': 8},
      {'month': 'Aug', 'count': 10},
      {'month': 'Sep', 'count': 11},
      {'month': 'Oct', 'count': 13},
      {'month': 'Nov', 'count': 9},
      {'month': 'Dec', 'count': 0},
    ];
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        // Already on dashboard page
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

  void _navigateToPatientDetails(Patient patient) {
    Navigator.of(context).pushNamed(
      '/patient-details',
      arguments: patient,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: 1,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildStatisticsCards(),
          const SizedBox(height: 30),
          _buildCharts(),
          const SizedBox(height: 30),
          _buildRecentActivity(),
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
            'Dashboard',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome back, ${_doctorSettings?.name?.split(' ').first ?? 'Doctor'}',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return FadeAnimation(
      delay: 0.3,
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Total Patients',
            value: _totalPatients.toString(),
            icon: Icons.people,
            color: AppTheme.primaryColor,
          ),
          _buildStatCard(
            title: 'Total Visits',
            value: _totalVisits.toString(),
            icon: Icons.calendar_today,
            color: AppTheme.secondaryColor,
          ),
          _buildStatCard(
            title: 'Prescriptions',
            value: _totalPrescriptions.toString(),
            icon: Icons.medication,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Lab Orders',
            value: _totalLabOrders.toString(),
            icon: Icons.science,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return FadeAnimation(
      delay: 0.4,
      child: Row(
        children: [
          Expanded(
            child: _buildVisitsChart(),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildPrescriptionsChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsChart() {
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
              'Visits by Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < _visitsByMonth.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _visitsByMonth[value.toInt()]['month'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          );
                        },
                        interval: 5,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(
                    _visitsByMonth.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _visitsByMonth[index]['count'].toDouble(),
                          color: AppTheme.primaryColor,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsChart() {
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
              'Prescriptions by Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < _prescriptionsByMonth.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _prescriptionsByMonth[value.toInt()]['month'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          );
                        },
                        interval: 5,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: _prescriptionsByMonth.length - 1.0,
                  minY: 0,
                  maxY: 20,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _prescriptionsByMonth.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          _prescriptionsByMonth[index]['count'].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: AppTheme.secondaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.secondaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return FadeAnimation(
      delay: 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildRecentPatientsCard(),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildRecentVisitsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatientsCard() {
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
              'Recent Patients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            if (_recentPatients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No patients yet',
                    style: TextStyle(
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentPatients.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final patient = _recentPatients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name.substring(0, 1).toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${patient.age} years, ${patient.gender}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _navigateToPatientDetails(patient),
                    ),
                    onTap: () => _navigateToPatientDetails(patient),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVisitsCard() {
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
              'Recent Visits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            if (_recentVisits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No visits yet',
                    style: TextStyle(
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentVisits.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final visit = _recentVisits[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                    ),
                    title: FutureBuilder<Patient?>(
                      future: DatabaseHelper.instance.readPatient(visit.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text(
                          'Loading patient...',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${visit.date}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLightColor,
                          ),
                        ),
                        Text(
                          visit.details,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLightColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.secondaryColor,
                      ),
                      onPressed: () async {
                        final patient = await DatabaseHelper.instance.readPatient(visit.patientId);
                        if (patient != null && mounted) {
                          Navigator.of(context).pushNamed(
                            '/visit-details',
                            arguments: {
                              'patient': patient,
                              'visit': visit,
                            },
                          );
                        }
                      },
                    ),
                    onTap: () async {
                      final patient = await DatabaseHelper.instance.readPatient(visit.patientId);
                      if (patient != null && mounted) {
                        Navigator.of(context).pushNamed(
                          '/visit-details',
                          arguments: {
                            'patient': patient,
                            'visit': visit,
                          },
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}