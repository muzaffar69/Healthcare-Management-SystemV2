import 'package:flutter/material.dart';

class ThemeConstants {
  // Main colors
  static const Color primaryColor = Color(0xFF7B63FF); // Purple
  static const Color secondaryColor = Color(0xFF00D68F); // Green
  static const Color accentColor = Color(0xFF3A3F5A); // Dark blue/grey
  static const Color warningColor = Color(0xFFFF7D69); // Orange/red

  // Background colors
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  
  // Text colors
  static const Color textColor = Color(0xFF3A3F5A);
  static const Color textLightColor = Color(0xFF8F95B2);
  static const Color textDarkColor = Color(0xFF2E3345);
  
  // Border and divider
  static const Color dividerColor = Color(0xFFE8ECFD);
  static const Color borderColor = Color(0xFFE8ECFD);
  
  // Status colors
  static const Color successColor = Color(0xFF00D68F);
  static const Color errorColor = Color(0xFFFF3D57);
  static const Color infoColor = Color(0xFF0095FF);
  
  // Button colors
  static const Color primaryButtonColor = primaryColor;
  static const Color secondaryButtonColor = secondaryColor;
  static const Color disabledButtonColor = Color(0xFFE8ECFD);
  
  // Icon colors
  static const Color iconColor = Color(0xFF606583);
  static const Color iconLightColor = Color(0xFF8F95B2);
  
  // Shadow
  static const Color shadowColor = Color(0x14000000);
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textColor,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLightColor,
  );
  
  // Spacings
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;
  
  // Borders
  static const double borderRadius = 10.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 10.0;
  static const double inputBorderRadius = 10.0;
  
  // Animations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Elevations
  static const double cardElevation = 5.0;
  static const double buttonElevation = 2.0;
  static const double dialogElevation = 10.0;
  
  // Icon sizes
  static const double defaultIconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;
}