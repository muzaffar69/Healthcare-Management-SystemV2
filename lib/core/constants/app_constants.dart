class AppConstants {
  // App information
  static const String appName = "Medical Practice Manager";
  static const String appVersion = "1.0.0";
  static const String appBuildNumber = "1";
  
  // Routes
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String dashboardRoute = '/dashboard';
  static const String patientsRoute = '/patients';
  static const String patientDetailsRoute = '/patient-details';
  static const String addPatientRoute = '/add-patient';
  static const String visitDetailsRoute = '/visit-details';
  static const String addVisitRoute = '/add-visit';
  static const String drugsRoute = '/drugs';
  static const String labTestsRoute = '/lab-tests';
  static const String settingsRoute = '/settings';
  
  // Database
  static const String databaseName = 'medical_practice.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String patientsTable = 'patients';
  static const String visitsTable = 'visits';
  static const String drugsTable = 'drugs';
  static const String labTestsTable = 'lab_tests';
  static const String prescriptionsTable = 'prescriptions';
  static const String labOrdersTable = 'lab_orders';
  static const String doctorSettingsTable = 'doctor_settings';
  
  // Cache keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';
  static const String firstLaunchKey = 'first_launch';
  
  // API Endpoints (for future cloud implementation)
  static const String baseApiUrl = 'https://api.medicalpractice.example.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String patientsEndpoint = '/patients';
  static const String visitsEndpoint = '/visits';
  static const String drugsEndpoint = '/drugs';
  static const String labTestsEndpoint = '/lab-tests';
  static const String prescriptionsEndpoint = '/prescriptions';
  static const String labOrdersEndpoint = '/lab-orders';
  static const String settingsEndpoint = '/settings';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'MMM dd, yyyy';
  
  // Gender options
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];
  
  // Doctor account types
  static const String doctorAccountType = 'doctor';
  static const String pharmacyAccountType = 'pharmacy';
  static const String labAccountType = 'laboratory';
  
  // PDF generation
  static const String prescriptionTitle = 'PRESCRIPTION';
  static const String labOrderTitle = 'LABORATORY TEST ORDER';
  static const String prescriptionFileName = 'prescription_';
  static const String labOrderFileName = 'lab_order_';
  
  // Dashboard analytics
  static const int recentPatientsLimit = 5;
  static const int recentVisitsLimit = 5;
  static const int topDrugsLimit = 5;
  static const int topLabTestsLimit = 5;
  
  // Error messages
  static const String generalErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';
  static const String databaseErrorMessage = 'Database error. Please restart the application.';
  
  // Success messages
  static const String saveSuccessMessage = 'Successfully saved!';
  static const String updateSuccessMessage = 'Successfully updated!';
  static const String deleteSuccessMessage = 'Successfully deleted!';
  
  // Default values
  static const String defaultDoctorName = 'Doctor';
  static const String defaultSpecialty = '';
  static const String emptyStateMessage = 'No data available.';
  
  // Feature flags (for future implementation)
  static const bool enableCloudSync = false;
  static const bool enableDarkMode = false;
  static const bool enableNotifications = false;
  static const bool enableAnalytics = true;
}