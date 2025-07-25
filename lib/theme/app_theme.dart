import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorPreset {
  arch('Arch Linux', 'Official Arch Linux colors'),
  originalPurple('Original Purple', 'Classic dark purple theme'),
  forest('Forest', 'Green nature theme'),
  ocean('Ocean', 'Blue ocean depths'),
  sunset('Sunset', 'Orange and pink sunset'),
  midnight('Midnight', 'Deep blue midnight'),
  cherry('Cherry', 'Red cherry blossom'),
  lavender('Lavender', 'Soft purple lavender'),
  ember('Ember', 'Warm orange ember'),
  mint('Mint', 'Cool mint green'),
  storm('Storm', 'Dark storm clouds');

  const ColorPreset(this.displayName, this.description);
  final String displayName;
  final String description;
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode as requested
  ColorPreset _colorPreset = ColorPreset.arch; // Default to Arch theme

  bool get isDarkMode => _isDarkMode;
  ColorPreset get colorPreset => _colorPreset;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? true; // Default to dark
      final presetIndex = prefs.getInt('color_preset') ?? 0; // Default to Arch
      _colorPreset = ColorPreset.values[presetIndex];
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  Future<void> setColorPreset(ColorPreset preset) async {
    _colorPreset = preset;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('color_preset', preset.index);
    } catch (e) {
      print('Error saving color preset: $e');
    }
  }

  ThemeData get currentTheme => _isDarkMode ? _getDarkTheme() : _getLightTheme();

  ThemeData _getDarkTheme() {
    switch (_colorPreset) {
      case ColorPreset.arch:
        return darkTheme;
      case ColorPreset.originalPurple:
        return originalPurpleDarkTheme;
      case ColorPreset.forest:
        return forestDarkTheme;
      case ColorPreset.ocean:
        return oceanDarkTheme;
      case ColorPreset.sunset:
        return sunsetDarkTheme;
      case ColorPreset.midnight:
        return midnightDarkTheme;
      case ColorPreset.cherry:
        return cherryDarkTheme;
      case ColorPreset.lavender:
        return lavenderDarkTheme;
      case ColorPreset.ember:
        return emberDarkTheme;
      case ColorPreset.mint:
        return mintDarkTheme;
      case ColorPreset.storm:
        return stormDarkTheme;
    }
  }

  ThemeData _getLightTheme() {
    switch (_colorPreset) {
      case ColorPreset.arch:
        return lightTheme;
      case ColorPreset.originalPurple:
        return originalPurpleLightTheme;
      case ColorPreset.forest:
        return forestLightTheme;
      case ColorPreset.ocean:
        return oceanLightTheme;
      case ColorPreset.sunset:
        return sunsetLightTheme;
      case ColorPreset.midnight:
        return midnightLightTheme;
      case ColorPreset.cherry:
        return cherryLightTheme;
      case ColorPreset.lavender:
        return lavenderLightTheme;
      case ColorPreset.ember:
        return emberLightTheme;
      case ColorPreset.mint:
        return mintLightTheme;
      case ColorPreset.storm:
        return stormLightTheme;
    }
  }
}

// Arch Linux Color Palette
class ArchColors {
  // Primary Signature Colors
  static const Color primaryBlue = Color(0xFF0057B8);           // Pantone 2935C
  static const Color darkGray = Color(0xFF333F48);             // Pantone 432C
  static const Color lightBeige = Color(0xFFDFD1A7);           // Pantone 7500C
  static const Color lightBlue = Color(0xFF5BC2E7);            // Pantone 2985C
  static const Color archGreen = Color(0xFF99C22C);            // Pantone 382U
  static const Color purple = Color(0xFF5F259F);               // Pantone 267C
  static const Color teal = Color(0xFF009CA6);                 // Pantone 320C
  static const Color red = Color(0xFFBA0C2F);                  // Pantone 200C
  static const Color yellow = Color(0xFFFEDB00);               // Pantone 108C
  static const Color orange = Color(0xFFFFA300);               // Pantone 137C

  // Dark Mode Specific Colors (darker shades)
  static const Color darkBackground = Color(0xFF001833);       // Very dark blue
  static const Color darkSurface = Color(0xFF00244D);          // Dark blue surface
  static const Color darkCard = Color(0xFF003066);             // Card background
  static const Color darkAccent = Color(0xFF004799);           // Accent blue
  
  // Dark variations for better contrast
  static const Color darkText = Color(0xFF1A1A1A);             // Very dark gray
  static const Color mediumGray = Color(0xFF333333);           // Medium gray
  static const Color lightGray = Color(0xFF4D4D4D);            // Light gray for dark mode
  
  // Teal variations for dark mode
  static const Color darkTeal = Color(0xFF003033);             // Very dark teal
  static const Color mediumTeal = Color(0xFF00474D);           // Medium teal
  static const Color accentTeal = Color(0xFF005F66);           // Accent teal
  
  // Purple variations for dark mode
  static const Color darkPurple = Color(0xFF190A29);           // Very dark purple
  static const Color mediumPurple = Color(0xFF250F3E);         // Medium purple
  static const Color accentPurple = Color(0xFF321353);         // Accent purple
  
  // Red variations for dark mode
  static const Color darkRed = Color(0xFF480512);              // Very dark red
  static const Color mediumRed = Color(0xFF600618);            // Medium red
  static const Color accentRed = Color(0xFF78081E);            // Accent red
  
  // Green variations for dark mode
  static const Color darkGreen = Color(0xFF232C07);            // Very dark green
  static const Color mediumGreen = Color(0xFF34410B);          // Medium green
  static const Color accentGreen = Color(0xFF45570F);          // Accent green
}

// Dark Theme (Default)
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  
  // Color Scheme
  colorScheme: const ColorScheme.dark(
    primary: ArchColors.primaryBlue,
    primaryContainer: ArchColors.darkAccent,
    secondary: ArchColors.lightBlue,
    secondaryContainer: ArchColors.accentTeal,
    tertiary: ArchColors.archGreen,
    tertiaryContainer: ArchColors.accentGreen,
    surface: ArchColors.darkSurface,
    surfaceContainer: ArchColors.darkCard,
    surfaceContainerHighest: ArchColors.darkGray,
    error: ArchColors.red,
    errorContainer: ArchColors.darkRed,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onSurface: Colors.white,
    onSurfaceVariant: Color(0xFFE1E2E1),
    onError: Colors.white,
    outline: ArchColors.mediumGray,
    outlineVariant: ArchColors.lightGray,
  ),
  
  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: ArchColors.darkBackground,
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  
  // Card Theme
  cardTheme: CardTheme(
    color: ArchColors.darkCard,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: ArchColors.primaryBlue.withOpacity(0.3),
        width: 1,
      ),
    ),
  ),
  
  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ArchColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: ArchColors.primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  
  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ArchColors.lightBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  
  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ArchColors.darkCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.mediumGray),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.mediumGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.red),
    ),
    labelStyle: const TextStyle(color: ArchColors.lightBlue),
    hintStyle: const TextStyle(color: ArchColors.mediumGray),
  ),
  
  // Text Theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Color(0xFFE1E2E1)),
    labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: Color(0xFFE1E2E1)),
  ),
  
  // Icon Theme
  iconTheme: const IconThemeData(
    color: ArchColors.lightBlue,
    size: 24,
  ),
  
  // Divider Theme
  dividerTheme: const DividerThemeData(
    color: ArchColors.mediumGray,
    thickness: 1,
  ),
  
  // Switch Theme
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return ArchColors.archGreen;
      }
      return ArchColors.mediumGray;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return ArchColors.archGreen.withOpacity(0.3);
      }
      return ArchColors.darkGray;
    }),
  ),
);

// Light Theme
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  
  // Color Scheme
  colorScheme: const ColorScheme.light(
    primary: ArchColors.primaryBlue,
    primaryContainer: Color(0xFF80ABDC), // 50% tint of primary blue
    secondary: ArchColors.teal,
    secondaryContainer: Color(0xFF80CED3), // 50% tint of teal
    tertiary: ArchColors.archGreen,
    tertiaryContainer: Color(0xFFCCE190), // 50% tint of green
    surface: Colors.white,
    surfaceContainer: Color(0xFFF5F5F5),
    surfaceContainerHighest: Color(0xFFE8E8E8),
    error: ArchColors.red,
    errorContainer: Color(0xFFEAB6C1), // 50% tint of red
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onSurface: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFF4D4D4D),
    onError: Colors.white,
    outline: Color(0xFFBDBDBD),
    outlineVariant: Color(0xFFE0E0E0),
  ),
  
  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ArchColors.darkGray,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: ArchColors.darkGray,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  
  // Card Theme
  cardTheme: CardTheme(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
  ),
  
  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ArchColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: ArchColors.primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  
  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ArchColors.primaryBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  
  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ArchColors.red),
    ),
    labelStyle: const TextStyle(color: ArchColors.darkGray),
    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
  ),
  
  // Text Theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
    bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
    bodySmall: TextStyle(color: Color(0xFF4D4D4D)),
    labelLarge: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: ArchColors.darkGray, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: Color(0xFF4D4D4D)),
  ),
  
  // Icon Theme
  iconTheme: const IconThemeData(
    color: ArchColors.primaryBlue,
    size: 24,
  ),
  
  // Divider Theme
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
  ),
  
  // Switch Theme
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return ArchColors.archGreen;
      }
      return const Color(0xFFBDBDBD);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return ArchColors.archGreen.withOpacity(0.3);
      }
      return const Color(0xFFE0E0E0);
    }),
  ),
);

// =============================================================================
// COLOR PRESET THEMES
// =============================================================================

// ORIGINAL PURPLE THEME (The classic one you mentioned)
final ThemeData originalPurpleDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF9B59B6),
    primaryContainer: Color(0xFF321353),
    secondary: Color(0xFFE91E63),
    secondaryContainer: Color(0xFF600618),
    tertiary: Color(0xFF673AB7),
    tertiaryContainer: Color(0xFF250F3E),
    surface: Color(0xFF1E1E1E),
    surfaceContainer: Color(0xFF2D2D30),
    surfaceContainerHighest: Color(0xFF333333),
    onPrimary: Colors.white,
    onPrimaryContainer: Color(0xFFE1BEE7),
    onSecondary: Colors.white,
    onSecondaryContainer: Color(0xFFFFB3BA),
    onTertiary: Colors.white,
    onTertiaryContainer: Color(0xFFD1C4E9),
    onSurface: Colors.white,
    onSurfaceVariant: Color(0xFFB3B3B3),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    outline: Color(0xFF4D4D4D),
  ),
);

final ThemeData originalPurpleLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF9B59B6),
    primaryContainer: Color(0xFFE1BEE7),
    secondary: Color(0xFFE91E63),
    secondaryContainer: Color(0xFFFFB3BA),
    tertiary: Color(0xFF673AB7),
    tertiaryContainer: Color(0xFFD1C4E9),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF5F5F5),
    surfaceContainerHighest: Color(0xFFE0E0E0),
  ),
);

// FOREST THEME
final ThemeData forestDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4CAF50),
    primaryContainer: Color(0xFF2E7D32),
    secondary: Color(0xFF8BC34A),
    secondaryContainer: Color(0xFF558B2F),
    tertiary: Color(0xFF66BB6A),
    tertiaryContainer: Color(0xFF388E3C),
    surface: Color(0xFF1B2E1A),
    surfaceContainer: Color(0xFF2A3E29),
    surfaceContainerHighest: Color(0xFF334D32),
  ),
);

final ThemeData forestLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4CAF50),
    primaryContainer: Color(0xFFC8E6C9),
    secondary: Color(0xFF8BC34A),
    secondaryContainer: Color(0xFFDCEDC8),
    tertiary: Color(0xFF66BB6A),
    tertiaryContainer: Color(0xFFA5D6A7),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF1F8E9),
  ),
);

// OCEAN THEME
final ThemeData oceanDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2196F3),
    primaryContainer: Color(0xFF1565C0),
    secondary: Color(0xFF03DAC6),
    secondaryContainer: Color(0xFF00695C),
    tertiary: Color(0xFF00BCD4),
    tertiaryContainer: Color(0xFF0277BD),
    surface: Color(0xFF0F1B2E),
    surfaceContainer: Color(0xFF1A2A3E),
    surfaceContainerHighest: Color(0xFF24394D),
  ),
);

final ThemeData oceanLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2196F3),
    primaryContainer: Color(0xFFBBDEFB),
    secondary: Color(0xFF03DAC6),
    secondaryContainer: Color(0xFFB2DFDB),
    tertiary: Color(0xFF00BCD4),
    tertiaryContainer: Color(0xFFB3E5FC),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF3F9FF),
  ),
);

// SUNSET THEME
final ThemeData sunsetDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF5722),
    primaryContainer: Color(0xFFD84315),
    secondary: Color(0xFFFF9800),
    secondaryContainer: Color(0xFFE65100),
    tertiary: Color(0xFFFFEB3B),
    tertiaryContainer: Color(0xFFF57F17),
    surface: Color(0xFF2E1B0F),
    surfaceContainer: Color(0xFF3E2A1A),
    surfaceContainerHighest: Color(0xFF4D3924),
  ),
);

final ThemeData sunsetLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF5722),
    primaryContainer: Color(0xFFFFCCBC),
    secondary: Color(0xFFFF9800),
    secondaryContainer: Color(0xFFFFE0B2),
    tertiary: Color(0xFFFFEB3B),
    tertiaryContainer: Color(0xFFFFF9C4),
    surface: Colors.white,
    surfaceContainer: Color(0xFFFFF8F5),
  ),
);

// MIDNIGHT THEME
final ThemeData midnightDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3F51B5),
    primaryContainer: Color(0xFF303F9F),
    secondary: Color(0xFF7986CB),
    secondaryContainer: Color(0xFF5C6BC0),
    tertiary: Color(0xFF9C27B0),
    tertiaryContainer: Color(0xFF7B1FA2),
    surface: Color(0xFF0A0A1A),
    surfaceContainer: Color(0xFF141426),
    surfaceContainerHighest: Color(0xFF1E1E33),
  ),
);

final ThemeData midnightLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF3F51B5),
    primaryContainer: Color(0xFFC5CAE9),
    secondary: Color(0xFF7986CB),
    secondaryContainer: Color(0xFFD1C4E9),
    tertiary: Color(0xFF9C27B0),
    tertiaryContainer: Color(0xFFE1BEE7),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF5F5FF),
  ),
);

// CHERRY THEME
final ThemeData cherryDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE91E63),
    primaryContainer: Color(0xFFC2185B),
    secondary: Color(0xFFFF6B9D),
    secondaryContainer: Color(0xFFAD1457),
    tertiary: Color(0xFFF48FB1),
    tertiaryContainer: Color(0xFF880E4F),
    surface: Color(0xFF2E0F1A),
    surfaceContainer: Color(0xFF3E1A26),
    surfaceContainerHighest: Color(0xFF4D2433),
  ),
);

final ThemeData cherryLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE91E63),
    primaryContainer: Color(0xFFF8BBD9),
    secondary: Color(0xFFFF6B9D),
    secondaryContainer: Color(0xFFFFCDD2),
    tertiary: Color(0xFFF48FB1),
    tertiaryContainer: Color(0xFFFCE4EC),
    surface: Colors.white,
    surfaceContainer: Color(0xFFFFF5F8),
  ),
);

// LAVENDER THEME
final ThemeData lavenderDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFB39DDB),
    primaryContainer: Color(0xFF7E57C2),
    secondary: Color(0xFFD1C4E9),
    secondaryContainer: Color(0xFF9575CD),
    tertiary: Color(0xFFE1BEE7),
    tertiaryContainer: Color(0xFFAB47BC),
    surface: Color(0xFF1A1426),
    surfaceContainer: Color(0xFF2A1E33),
    surfaceContainerHighest: Color(0xFF392940),
  ),
);

final ThemeData lavenderLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFB39DDB),
    primaryContainer: Color(0xFFEDE7F6),
    secondary: Color(0xFFD1C4E9),
    secondaryContainer: Color(0xFFF3E5F5),
    tertiary: Color(0xFFE1BEE7),
    tertiaryContainer: Color(0xFFFCE4EC),
    surface: Colors.white,
    surfaceContainer: Color(0xFFFAF8FF),
  ),
);

// EMBER THEME
final ThemeData emberDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF7043),
    primaryContainer: Color(0xFFD84315),
    secondary: Color(0xFFFFAB40),
    secondaryContainer: Color(0xFFFF8F00),
    tertiary: Color(0xFFFF8A65),
    tertiaryContainer: Color(0xFFBF360C),
    surface: Color(0xFF2E1A0F),
    surfaceContainer: Color(0xFF3E261A),
    surfaceContainerHighest: Color(0xFF4D3324),
  ),
);

final ThemeData emberLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF7043),
    primaryContainer: Color(0xFFFFCCBC),
    secondary: Color(0xFFFFAB40),
    secondaryContainer: Color(0xFFFFE0B2),
    tertiary: Color(0xFFFF8A65),
    tertiaryContainer: Color(0xFFFFE0D1),
    surface: Colors.white,
    surfaceContainer: Color(0xFFFFF8F5),
  ),
);

// MINT THEME
final ThemeData mintDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF26A69A),
    primaryContainer: Color(0xFF00695C),
    secondary: Color(0xFF4DB6AC),
    secondaryContainer: Color(0xFF00796B),
    tertiary: Color(0xFF80CBC4),
    tertiaryContainer: Color(0xFF004D40),
    surface: Color(0xFF0F2E26),
    surfaceContainer: Color(0xFF1A3E33),
    surfaceContainerHighest: Color(0xFF244D40),
  ),
);

final ThemeData mintLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF26A69A),
    primaryContainer: Color(0xFFB2DFDB),
    secondary: Color(0xFF4DB6AC),
    secondaryContainer: Color(0xFFE0F2F1),
    tertiary: Color(0xFF80CBC4),
    tertiaryContainer: Color(0xFFE0F7FA),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF0FDF5),
  ),
);

// STORM THEME
final ThemeData stormDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF607D8B),
    primaryContainer: Color(0xFF455A64),
    secondary: Color(0xFF90A4AE),
    secondaryContainer: Color(0xFF546E7A),
    tertiary: Color(0xFFB0BEC5),
    tertiaryContainer: Color(0xFF37474F),
    surface: Color(0xFF1A1F23),
    surfaceContainer: Color(0xFF262B30),
    surfaceContainerHighest: Color(0xFF33383D),
  ),
);

final ThemeData stormLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF607D8B),
    primaryContainer: Color(0xFFCFD8DC),
    secondary: Color(0xFF90A4AE),
    secondaryContainer: Color(0xFFECEFF1),
    tertiary: Color(0xFFB0BEC5),
    tertiaryContainer: Color(0xFFF5F5F5),
    surface: Colors.white,
    surfaceContainer: Color(0xFFF8F9FA),
  ),
);
