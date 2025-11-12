import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tokens.dart';

/// 테마 모드 Notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;
  
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// 테마 모드 Provider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 온기 앱 테마
class OngiTheme {
  OngiTheme._();
  
  /// 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: OngiTokens.primary,
        secondary: OngiTokens.accent,
        surface: OngiTokens.bg,
        background: OngiTokens.bg,
        error: OngiTokens.warn,
        onPrimary: Colors.white,
        onSecondary: OngiTokens.ink,
        onSurface: OngiTokens.ink,
        onBackground: OngiTokens.ink,
      ),
      scaffoldBackgroundColor: OngiTokens.bg,
      fontFamily: OngiTokens.fontFamily,
      fontFamilyFallback: OngiTokens.fontFamilyFallback,
      textTheme: _buildTextTheme(OngiTokens.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OngiTokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OngiTokens.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OngiTokens.radius),
          ),
          minimumSize: const Size(0, OngiTokens.minTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: OngiTokens.spacingScreen,
          vertical: OngiTokens.spacingCard / 2,
        ),
      ),
    );
  }
  
  /// 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: OngiTokens.primaryDark,
        secondary: OngiTokens.accent,
        surface: OngiTokens.bgDark,
        background: OngiTokens.bgDark,
        error: OngiTokens.warn,
        onPrimary: OngiTokens.inkDark,
        onSecondary: OngiTokens.inkDark,
        onSurface: OngiTokens.inkDark,
        onBackground: OngiTokens.inkDark,
      ),
      scaffoldBackgroundColor: OngiTokens.bgDark,
      fontFamily: OngiTokens.fontFamily,
      fontFamilyFallback: OngiTokens.fontFamilyFallback,
      textTheme: _buildTextTheme(OngiTokens.inkDark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OngiTokens.bgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radiusSmall),
          borderSide: BorderSide(color: OngiTokens.primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OngiTokens.primaryDark,
          foregroundColor: OngiTokens.inkDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OngiTokens.radius),
          ),
          minimumSize: const Size(0, OngiTokens.minTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF3A3128),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OngiTokens.radius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: OngiTokens.spacingScreen,
          vertical: OngiTokens.spacingCard / 2,
        ),
      ),
    );
  }
  
  /// 텍스트 테마 생성 (라인 하이트 고정)
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: OngiTokens.lineHeightTight,
      ),
      displayMedium: TextStyle(
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: OngiTokens.lineHeightTight,
      ),
      displaySmall: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: OngiTokens.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: OngiTokens.lineHeightNormal,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: OngiTokens.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: OngiTokens.lineHeightNormal,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: OngiTokens.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: OngiTokens.lineHeightRelaxed,
      ),
      bodySmall: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: OngiTokens.lineHeightNormal,
      ),
      labelLarge: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: OngiTokens.lineHeightNormal,
      ),
    );
  }
}

