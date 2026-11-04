import 'package:flutter/material.dart';

/// MuseFlow design tokens — "Aurora Noir".
///
/// A near-black stage, layered glass surfaces and a single aurora gradient are
/// used consistently across the product to keep the interface calm and premium.
class AppColors {
  AppColors._();

  static const background = Color(0xFF06070D);
  static const backgroundSoft = Color(0xFF0A0C15);
  static const surface = Color(0xFF10121F);
  static const surfaceHigh = Color(0xFF171A2C);
  static const surfaceGlass = Color(0x14FFFFFF);

  static const textPrimary = Color(0xFFF4F5FC);
  static const textSecondary = Color(0xFF9AA0BC);
  static const textTertiary = Color(0xFF646A86);

  static const violet = Color(0xFF8B5CF6);
  static const violetSoft = Color(0xFFA78BFA);
  static const cyan = Color(0xFF22D3EE);
  static const mint = Color(0xFF34D399);
  static const pink = Color(0xFFF472B6);
  static const amber = Color(0xFFFBBF24);
  static const danger = Color(0xFFFB7185);

  static const line = Color(0x14FFFFFF);
  static const lineStrong = Color(0x26FFFFFF);

  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan, mint],
  );

  static const auroraHorizontal = LinearGradient(
    colors: [violetSoft, cyan, mint],
  );

  static const violetGlow = RadialGradient(
    colors: [Color(0x668B5CF6), Color(0x008B5CF6)],
  );
  static const cyanGlow = RadialGradient(
    colors: [Color(0x3D22D3EE), Color(0x0022D3EE)],
  );
}

class AppRadii {
  AppRadii._();
  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
  static const pill = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: 'Inter',
    );

    const scheme = ColorScheme.dark(
      primary: AppColors.cyan,
      onPrimary: Color(0xFF04141A),
      secondary: AppColors.violet,
      onSecondary: Colors.white,
      tertiary: AppColors.mint,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.lineStrong,
      error: AppColors.danger,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
          fontFamily: 'Inter',
        )
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: 56,
            height: 1.04,
            letterSpacing: -1.8,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          displayMedium: const TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: 40,
            height: 1.08,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          displaySmall: const TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: 32,
            height: 1.12,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          headlineMedium: const TextStyle(
            fontSize: 26,
            height: 1.2,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          headlineSmall: const TextStyle(
            fontSize: 21,
            height: 1.25,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: const TextStyle(
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.textTertiary,
          ),
          labelLarge: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.14),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }
}
