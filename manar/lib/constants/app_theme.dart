import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {      
  static const Color maroon = Color.fromARGB(255, 118, 37, 37);
  static const Color gold = Color.fromARGB(255, 191, 170, 102);
  static const Color darkNavy = Color(0xFF191943);        
  static const Color primaryBlue = Color(0xFF344D80);     
  static const Color lightGray = Color(0xFFDBDEE6);       
  static const Color mediumGray = Color(0xFF7B829E);      
  static const Color darkPurple = Color(0xFF1C1B49);    
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(AppColors.maroon),
      primaryColor: AppColors.maroon,
      scaffoldBackgroundColor: AppColors.darkNavy,
      
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.amiri(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.maroon,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.maroon,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gold,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          color: Colors.white70,
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.6),
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
      
      cardTheme: CardThemeData(
          color: AppColors.primaryBlue,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    );
  }
  
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class AppStyles {
  static BoxDecoration gradientContainer = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primaryBlue, AppColors.mediumGray],
    ),
    borderRadius: BorderRadius.circular(16),
  );
  
  static BoxDecoration goldGradientContainer = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
    ),
    borderRadius: BorderRadius.circular(16),
  );
  
  static BoxDecoration glassmorphicContainer = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
    ),
  );
  
  static EdgeInsets defaultPadding = EdgeInsets.all(24);
  static EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 24);
  static EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 24);
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 600);
}

extension TextStyleExtensions on TextTheme {
  TextStyle get arabicTitle => GoogleFonts.amiri(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
  );
  
  TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: 14,
    color: Colors.white70,
  );
}