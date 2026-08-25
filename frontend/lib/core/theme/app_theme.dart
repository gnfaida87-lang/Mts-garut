import 'package:flutter/material.dart';

class AppTheme {
  // ── Light Brown Palette (Coklat Muda) ──
  static const Color primary = Color(0xFF9C6644);
  static const Color primaryDark = Color(0xFF6F4E37);
  static const Color primaryLight = Color(0xFFF5EBE0);
  static const Color secondary = Color(0xFFF9A825);
  static const Color secondaryLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF1F5F9);

  // ── Accent Colors ──
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFFDBEAFE);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFEDD5);
  static const Color teal = Color(0xFF14B8A6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEE2E2);

  // ── Neutral ──
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Gradient Presets ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFB08968)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryDarkGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF6F4E37), Color(0xFF9C6644), Color(0xFFB08968)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: Color(0xFF6F4E37),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: Color(0xFF78350F),
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: grey800,
        outline: grey300,
        outlineVariant: grey200,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: grey800,
        elevation: 0,
        centerTitle: false,
        shadowColor: Color(0x0A000000),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: grey200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: grey400, fontSize: 14),
        labelStyle: const TextStyle(color: grey500, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: grey300,
          disabledForegroundColor: grey500,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryDark);
          }
          return const TextStyle(fontSize: 11, color: grey500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: grey400, size: 22);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        labelType: NavigationRailLabelType.all,
        unselectedLabelTextStyle: TextStyle(fontSize: 12, color: grey500),
        selectedLabelTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryDark),
        selectedIconTheme: IconThemeData(color: primary, size: 22),
        unselectedIconTheme: IconThemeData(color: grey400, size: 22),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryDark,
        unselectedLabelColor: grey500,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryLight;
          }
          return Colors.transparent;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey100,
        selectedColor: primaryLight,
        disabledColor: grey100,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: grey200),
        ),
        side: const BorderSide(color: grey200),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: grey200,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
