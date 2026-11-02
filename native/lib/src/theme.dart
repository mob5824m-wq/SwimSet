import 'package:flutter/material.dart';

class SwimTheme {
  static const Color seed = Color(0xFF0E7490);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final outline = isDark ? const Color(0xFF27414C) : const Color(0xFFD9E6EC);
    final fieldFill = isDark ? const Color(0xFF12242C) : Colors.white;
    final muted = isDark ? const Color(0xFF91A9B5) : const Color(0xFF57717E);

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Lato',
      scaffoldBackgroundColor: isDark ? const Color(0xFF08151B) : const Color(0xFFF3F8FA),
      dividerColor: outline,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF0E1F27) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF08151B) : const Color(0xFFF3F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w400),
        border: border(outline),
        enabledBorder: border(outline),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(color: isDark ? const Color(0xFF2B4652) : const Color(0xFFC9DCE4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        // Chips need an explicit label colour: a bare text style loses the
        // colour and the text inherits the surrounding (white) default.
        labelStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0B1B23) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
          fontFamily: 'Lato',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF0B1B23) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontWeight: FontWeight.w600,
          color: muted,
        ),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: scheme.onSurface),
        headlineMedium: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: scheme.onSurface),
        headlineSmall: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: scheme.onSurface),
        titleLarge: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: scheme.onSurface),
        titleMedium: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyMedium: TextStyle(fontFamily: 'Lato', color: scheme.onSurface),
        bodySmall: TextStyle(fontFamily: 'Lato', color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  static Color muted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF91A9B5) : const Color(0xFF57717E);
  }

  static Color line(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF27414C) : const Color(0xFFD9E6EC);
  }
}
