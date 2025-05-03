class AppConstants {
  // App info
  static const String appName = 'Medical Practice Management';
  static const String appVersion = '1.0.0';
  
  // Azure configuration
  static const String azureAdTenant = 'azureAdTenant';
  static const String azureClientId = 'azureClientId';
  static const String azureRedirectUri = 'azureRedirectUri';
  static const String azureGraphScope = 'azureGraphScope';
  
  // Database configuration
  static const String dbConnectionString = 'dbConnectionString';
  static const String blobConnectionString = 'blobConnectionString';
  
  // API endpoints
  static const String apiBaseUrl = 'apiBaseUrl';
  
  // Shared preferences keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String settingsKey = 'settings';
  static const String offlineDataKey = 'offlineData';
  static const String lastSyncKey = 'lastSync';
  
  // User roles
  static const String roleDoctor = 'doctor';
  static const String rolePharmacy = 'pharmacy';
  static const String roleLaboratory = 'laboratory';
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';
  
  // Default timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Sync intervals
  static const int syncInterval = 300000; // 5 minutes
  static const int backgroundSyncInterval = 1800000; // 30 minutes
  
  // Cache durations
  static const int cacheDuration = 86400000; // 24 hours
  
  // Subscription notification thresholds (in days)
  static const List<int> subscriptionNotificationDays = [30, 15, 7, 3, 1];
  
  // Image quality and size limits
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int jpegQuality = 85;
  
  // Animation durations
  static const int shortAnimationDuration = 150; // milliseconds
  static const int mediumAnimationDuration = 300; // milliseconds
  static const int longAnimationDuration = 500; // milliseconds
  
  // PDF generation settings
  static const double pdfPageWidth = 210.0; // A4 width in mm
  static const double pdfPageHeight = 297.0; // A4 height in mm
  static const double pdfMargin = 20.0; // mm
  
  // Error messages
  static const String errorNoInternet = 'No internet connection. Some features may be limited.';
  static const String errorServerConnection = 'Could not connect to server. Please try again later.';
  static const String errorDatabaseConnection = 'Database connection error. Please contact support.';
  static const String errorAuthentication = 'Authentication failed. Please check your credentials.';
  static const String errorUnauthorized = 'You are not authorized to access this feature.';
  static const String errorSubscriptionExpired = 'Your subscription has expired. Please renew to continue using all features.';
  static const String errorLabInactive = 'Laboratory account is inactive. Laboratory features are disabled.';
  static const String errorPharmacyInactive = 'Pharmacy account is inactive. Pharmacy features are disabled.';
  
  // Success messages
  static const String successSave = 'Data saved successfully.';
  static const String successSync = 'Data synchronized successfully.';
  static const String successSendPrescription = 'Prescription sent to pharmacy successfully.';
  static const String successSendLabOrder = 'Lab order sent successfully.';
  static const String successPatientAdd = 'Patient added successfully.';
}
