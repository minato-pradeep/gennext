import 'package:flutter/material.dart';

class AppTheme {
  // Base font family for the entire app
  static const String fontFamily = 'Arial Narrow';
  // ==================== COLORS ====================
  
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryDarkBlue = Color(0xFF0D47A1);
  static const Color primaryLightBlue = Color(0xFF1E88E5);
  
  // Secondary Colors — semantic only
  static const Color secondaryGreen = Color(0xFF12B76A);   // Success / Approved / Completed
  static const Color secondaryDarkGreen = Color(0xFF0E9558);
  static const Color secondaryLightGreen = Color(0xFF32D583);
  
  // Accent Colors — semantic only
  static const Color accentPurple = Color(0xFF7F56D9);     // Limited secondary accent
  static const Color accentOrange = Color(0xFFF79009);     // Pending / Attention
  static const Color accentRed = Color(0xFFF04438);        // Error / Rejected / Emergency
  static const Color accentTeal = Color(0xFF1565C0);       // Mapped to primary blue
  
  // Neutral Colors - Light Mode
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextHint = Color(0xFFD0D5DD);
  static const Color lightDivider = Color(0xFFE4E7EC);
  
  // Neutral Colors - Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextHint = Color(0xFF6B6B6B);
  static const Color darkDivider = Color(0xFF3D3D3D);
  
  // Status Colors
  static const Color success = Color(0xFF12B76A);   // Approved / Completed
  static const Color warning = Color(0xFFF79009);   // Pending / Attention
  static const Color error = Color(0xFFF04438);     // Error / Rejected
  static const Color info = Color(0xFF1565C0);      // Information / Active

  static Color brand(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color onBrand(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  /// The primary text color — reads from colorScheme.onSurface so custom
  /// text color picked via the Color Picker applies app-wide automatically.
  static Color textColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color brandLight(BuildContext context) =>
      Color.lerp(Theme.of(context).colorScheme.primary, Colors.white, 0.22)!;

  static LinearGradient brandGradient(BuildContext context) {
    final color = brand(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, Color.lerp(color, Colors.white, 0.22)!],
    );
  }
  
  // Gradients — subtle blue, no bright multi-color gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryLightBlue],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryLightBlue],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, Color(0xFF9E77ED)],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF1A2C42)],
  );
  
  // ==================== TYPOGRAPHY ====================
  
  static TextStyle get heading1 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static TextStyle get heading2 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static TextStyle get heading3 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  
  static TextStyle get heading4 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleSmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get caption => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle get buttonText => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // ==================== SHADOWS ====================
  
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glow(BuildContext context) => [
    BoxShadow(
      color: brand(context).withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 4,
    ),
  ];
  
  // ==================== SPACING ====================
  
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // ==================== BORDER RADIUS ====================
  
  static BorderRadius radiusXS = BorderRadius.circular(6);
  static BorderRadius radiusS = BorderRadius.circular(10);
  static BorderRadius radiusM = BorderRadius.circular(12);
  static BorderRadius radiusL = BorderRadius.circular(16);
  static BorderRadius radiusXL = BorderRadius.circular(20);
  static BorderRadius radiusXXL = BorderRadius.circular(28);
  static BorderRadius radiusCircle = BorderRadius.circular(100);
  
  // ==================== ANIMATION DURATIONS ====================
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationPage = Duration(milliseconds: 400);
  
  // ==================== CURVES ====================
  
  static const Curve curveFastOutSlowIn = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.easeOutBack;
  static const Curve curveElastic = Curves.elasticOut;
  
  // ==================== THEME DATA ====================
  
  static ThemeData get lightTheme => lightThemeWith(primaryBlue);

  static ThemeData lightThemeWith(Color primary, {Color onPrimary = Colors.white, Color? onSurface}) {
    final textColor = onSurface ?? lightTextPrimary;
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    primaryColor: primary,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dividerColor: lightDivider,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accentPurple,
      surface: lightSurface,
      error: error,
      onPrimary: onPrimary,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      iconTheme: IconThemeData(color: textColor),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radiusL),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBackground,
      border: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingL),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: spacingXL, vertical: spacingM),
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingXL, vertical: spacingM),
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        side: const BorderSide(color: lightDivider),
        textStyle: buttonText,
      ),
    ),
  );
  }
  
  static ThemeData get darkTheme => darkThemeWith(primaryBlue);

  static ThemeData darkThemeWith(Color primary, {Color onPrimary = Colors.white, Color? onSurface}) {
    final textColor = onSurface ?? darkTextPrimary;
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkDivider,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accentPurple,
      surface: darkSurface,
      error: error,
      onPrimary: onPrimary,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      iconTheme: IconThemeData(color: textColor),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radiusL),
      clipBehavior: Clip.antiAlias,
      color: darkCard,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingL),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: spacingXL, vertical: spacingM),
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        textStyle: buttonText,
      ),
    ),
  );
  }
}