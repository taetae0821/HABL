import 'package:flutter/material.dart';

// 앱 전체 색상: 활기찬 코랄 + 산뜻한 민트 + 따뜻한 크림 배경
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF6B4A); // 코랄 오렌지 (메인)
  static const primaryDark = Color(0xFFE8502F);
  static const primaryLight = Color(0xFFFFECE6);

  static const secondary = Color(0xFF1FB5A4); // 민트 틸 (포인트)
  static const secondaryLight = Color(0xFFE0F6F3);

  static const leader = Color(0xFFF2A516); // 회장 전용 골드
  static const leaderDark = Color(0xFFB9780A);

  static const background = Color(0xFFFFF8F3); // 크림
  static const surface = Colors.white;
  static const border = Color(0xFFF1E6DF);

  static const textPrimary = Color(0xFF2D2A32);
  static const textSecondary = Color(0xFF7A7280);
  static const textHint = Color(0xFFB5ADB8);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A5B), Color(0xFFFF5E62)],
  );

  static List<BoxShadow> softShadow([Color color = const Color(0xFF8A5A44)]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

// 동호회 카테고리: 이름 / 이모지 / 대표 색
class ClubCategory {
  const ClubCategory(this.name, this.emoji, this.color);

  final String name;
  final String emoji;
  final Color color;

  Color get light => color.withValues(alpha: 0.13);
  Color get dark => Color.lerp(color, Colors.black, 0.3)!;
}

const List<ClubCategory> clubCategories = [
  ClubCategory('운동', '⚽', Color(0xFFFF6B4A)),
  ClubCategory('스터디', '📚', Color(0xFF4C7DF0)),
  ClubCategory('음악', '🎸', Color(0xFF9B5DE5)),
  ClubCategory('미술/공예', '🎨', Color(0xFFF15BB5)),
  ClubCategory('여행', '✈️', Color(0xFF1FB5A4)),
  ClubCategory('게임', '🎮', Color(0xFF5A67D8)),
  ClubCategory('봉사활동', '🤝', Color(0xFF3DAA5C)),
  ClubCategory('기타', '✨', Color(0xFFF2A516)),
];

ClubCategory categoryOf(String name) => clubCategories.firstWhere(
      (c) => c.name == name,
      orElse: () => clubCategories.last,
    );

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
  );

  OutlineInputBorder outline(Color color, [double width = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: outline(AppColors.border),
      enabledBorder: outline(AppColors.border),
      focusedBorder: outline(AppColors.primary, 1.6),
      errorBorder: outline(colorScheme.error, 1.4),
      focusedErrorBorder: outline(colorScheme.error, 1.6),
      hintStyle: const TextStyle(color: AppColors.textHint),
      prefixIconColor: AppColors.textHint,
      suffixIconColor: AppColors.textHint,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primaryLight,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border),
  );
}
