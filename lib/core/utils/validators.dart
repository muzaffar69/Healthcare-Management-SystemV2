class Validators {
  /// Validates an email address
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty is allowed in some cases
    }
    
    // Simple regex for email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a phone number
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Check if we have a reasonable number of digits
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validates a name
  /// Returns null if valid, error message if invalid
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (value.length < 2) {
      return 'Name is too short';
    }
    
    // Check if name contains at least some letters
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Please enter a valid name';
    }
    
    return null;
  }
  
  /// Validates a numeric field (age, weight, etc.)
  /// Returns null if valid, error message if invalid
  static String? validateNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) {
      return null; // Empty is allowed in some cases
    }
    
    final number = num.tryParse(value);
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }
  
  /// Validates an integer field (age, etc.)
  /// Returns null if valid, error message if invalid
  static String? validateInteger(String? value, {String fieldName = 'Value', int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return null; // Empty is allowed in some cases
    }
    
    final number = int.tryParse(value);
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }
  
  /// Validates patient age
  /// Returns null if valid, error message if invalid
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 0) {
      return 'Age cannot be negative';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }
  
  /// Validates a date in yyyy-MM-dd format
  /// Returns null if valid, error message if invalid
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty is allowed in some cases
    }
    
    // Regex for yyyy-MM-dd format
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    if (!dateRegex.hasMatch(value)) {
      return 'Please use format: yyyy-MM-dd';
    }
    
    // Parse the date parts
    final parts = value.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    
    if (year == null || month == null || day == null) {
      return 'Invalid date';
    }
    
    // Basic validation for month/day values
    if (month < 1 || month > 12) {
      return 'Month must be between 1 and 12';
    }
    
    final daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (day < 1 || day > daysInMonth[month - 1]) {
      return 'Invalid day for month';
    }
    
    return null;
  }
  
  /// Validates a password
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }
  
  /// Confirms that two passwords match
  /// Returns null if valid, error message if invalid
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}