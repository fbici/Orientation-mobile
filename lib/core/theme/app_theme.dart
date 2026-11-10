import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6900E8);
  static const Color primaryLight = Color(0xFF9D20FF);
  static const Color primaryDark = Color(0xFF39008A);
  static const Color primarySurface = Color(0xFFF4EEFF);
  static const Color primaryMuted = Color(0xFFE5D5FF);

  // Accent
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentSurface = Color(0xFFF5F3FF);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF100C50);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSurface = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSurface = Color(0xFFF0F9FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6900E8), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
            headlineLarge: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: gray900,
              letterSpacing: -0.5,
            ),
            headlineMedium: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: gray900,
            ),
            titleLarge: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: gray900,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: gray900,
            ),
            bodyLarge: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: gray700,
              height: 1.5,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: gray600,
              height: 1.5,
            ),
            bodySmall: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: gray500,
            ),
            labelLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: gray900,
            ),
            labelMedium: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: gray700,
              letterSpacing: 0.5,
            ),
            labelSmall: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: gray500,
              letterSpacing: 0.5,
            ),
          ),
      scaffoldBackgroundColor: const Color(0xFFF9F7FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF9F7FF),
        foregroundColor: gray900,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: gray900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFCFAFF),
        indicatorColor: primaryMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : gray500)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : gray600)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)))),
      listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          iconColor: primary,
          titleTextStyle: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: gray900),
          subtitleTextStyle:
              TextStyle(fontSize: 13, height: 1.5, color: gray600)),
      expansionTileTheme:
          const ExpansionTileThemeData(iconColor: primary, textColor: gray900),
      chipTheme: ChipThemeData(
          backgroundColor: primarySurface,
          side: const BorderSide(color: primaryMuted),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: primaryMuted, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gray700,
          side: const BorderSide(color: gray300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gray600,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: gray400,
        ),
      ),
      dividerTheme: const DividerThemeData(color: gray200, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
