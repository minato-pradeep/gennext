import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class BrandColorOption {
  final String id;
  final String name;
  final Color color;
  final Color onColor;

  const BrandColorOption({
    required this.id,
    required this.name,
    required this.color,
    required this.onColor,
  });
}

/// A single entry in the 30-color custom picker palette.
class PickerColor {
  final String name;
  final Color color;
  const PickerColor(this.name, this.color);
}

class ThemeProvider extends ChangeNotifier {
  static const String defaultBrandId = 'blue';

  // SharedPreferences keys
  static const String _keyDarkMode    = 'isDarkMode';
  static const String _keyBrandId     = 'brandColorId';
  static const String _keyCustomBg    = 'customBgColor';
  static const String _keyCustomText  = 'customTextColor';

  // ── 30 predefined colors for the custom picker ──────────────────────────
  static const List<PickerColor> pickerColors = [
    // Reds & Pinks
    PickerColor('Crimson',        Color(0xFFDC143C)),
    PickerColor('Coral Red',      Color(0xFFFF6B6B)),
    PickerColor('Rose Pink',      Color(0xFFFF8FAB)),
    PickerColor('Blush',          Color(0xFFFFB3C1)),
    // Oranges & Yellows
    PickerColor('Deep Orange',    Color(0xFFFF5722)),
    PickerColor('Amber',          Color(0xFFFFC107)),
    PickerColor('Soft Yellow',    Color(0xFFFFF176)),
    PickerColor('Muted Orange',   Color(0xFFFFCC80)),
    // Greens
    PickerColor('Forest Green',   Color(0xFF2E7D32)),
    PickerColor('Emerald',        Color(0xFF26A65B)),
    PickerColor('Mint Green',     Color(0xFF80CBC4)),
    PickerColor('Sage Green',     Color(0xFFA5D6A7)),
    PickerColor('Pale Lime',      Color(0xFFDCEDC8)),
    // Blues
    PickerColor('Navy Blue',      Color(0xFF0D47A1)),
    PickerColor('Royal Blue',     Color(0xFF1565C0)),
    PickerColor('Sky Blue',       Color(0xFF29B6F6)),
    PickerColor('Baby Blue',      Color(0xFFB3E5FC)),
    PickerColor('Muted Slate',    Color(0xFFE2E8F0)),
    // Purples & Violets
    PickerColor('Deep Purple',    Color(0xFF4A148C)),
    PickerColor('Violet',         Color(0xFF7F56D9)),
    PickerColor('Lavender',       Color(0xFFCE93D8)),
    PickerColor('Soft Lilac',     Color(0xFFEDE7F6)),
    // Neutrals & Grays
    PickerColor('Charcoal',       Color(0xFF37474F)),
    PickerColor('Soft Blue-Gray', Color(0xFF78909C)),
    PickerColor('Silver',         Color(0xFFB0BEC5)),
    PickerColor('Cool Soft Gray', Color(0xFFF4F6F9)),
    // Browns & Tans
    PickerColor('Mocha',          Color(0xFF795548)),
    PickerColor('Warm Beige',     Color(0xFFD7CCC8)),
    // Dark & Light anchors
    PickerColor('Pure Black',     Color(0xFF000000)),
    PickerColor('Pure White',     Color(0xFFFFFFFF)),
  ];

  // ── Existing brand-color presets ────────────────────────────────────────
  static const List<BrandColorOption> brandOptions = [
    BrandColorOption(id: 'blue',   name: 'Blue',   color: Color(0xFF1565C0), onColor: Colors.white),
    BrandColorOption(id: 'red',    name: 'Red',    color: Color(0xFFE57373), onColor: Colors.white),
    BrandColorOption(id: 'yellow', name: 'Yellow', color: Color(0xFFFDD835), onColor: Color(0xFF172033)),
    BrandColorOption(id: 'green',  name: 'Green',  color: Color(0xFF81C784), onColor: Colors.white),
    BrandColorOption(id: 'orange', name: 'Orange', color: Color(0xFFFFB74D), onColor: Colors.white),
    BrandColorOption(id: 'brown',  name: 'Brown',  color: Color(0xFFA1887F), onColor: Colors.white),
  ];

  // ── State ────────────────────────────────────────────────────────────────
  bool   _isDarkMode = false;
  String _brandId    = defaultBrandId;

  /// When non-null, overrides the brand-preset background color.
  Color? _customBgColor;

  /// When non-null, overrides the brand-preset text-on-primary color.
  Color? _customTextColor;

  bool   get isDarkMode     => _isDarkMode;
  String get brandId        => _brandId;
  Color? get customBgColor   => _customBgColor;
  Color? get customTextColor => _customTextColor;

  /// Whether the user has an active custom color pair.
  bool get hasCustomColors => _customBgColor != null && _customTextColor != null;

  // ── Derived colors (consumed by main.dart → MaterialApp) ────────────────
  Color get primaryColor {
    if (_customBgColor != null) return _customBgColor!;
    for (final o in brandOptions) {
      if (o.id == _brandId) return o.color;
    }
    return AppTheme.primaryBlue;
  }

  Color get onPrimaryColor {
    if (_customTextColor != null) return _customTextColor!;
    for (final o in brandOptions) {
      if (o.id == _brandId) return o.onColor;
    }
    return Colors.white;
  }

  // ── Constructor ──────────────────────────────────────────────────────────
  ThemeProvider() {
    _loadTheme();
  }

  // ── Persistence ──────────────────────────────────────────────────────────
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _brandId    = prefs.getString(_keyBrandId) ?? defaultBrandId;

    final bgVal   = prefs.getInt(_keyCustomBg);
    final textVal = prefs.getInt(_keyCustomText);
    _customBgColor   = bgVal   != null ? Color(bgVal)   : null;
    _customTextColor = textVal != null ? Color(textVal) : null;

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveTheme();
    notifyListeners();
  }

  Future<void> saveBrandColor(String id) async {
    _brandId = id;
    // Saving a preset clears any custom override so they don't conflict.
    _customBgColor   = null;
    _customTextColor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBrandId, _brandId);
    await prefs.remove(_keyCustomBg);
    await prefs.remove(_keyCustomText);
    notifyListeners();
  }

  /// Save a custom (bg, text) color pair from the picker.
  Future<void> saveCustomColors({
    required Color bgColor,
    required Color textColor,
  }) async {
    _customBgColor   = bgColor;
    _customTextColor = textColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCustomBg,   ((bgColor.a * 255).round() << 24) | ((bgColor.r * 255).round() << 16) | ((bgColor.g * 255).round() << 8) | (bgColor.b * 255).round());
    await prefs.setInt(_keyCustomText, ((textColor.a * 255).round() << 24) | ((textColor.r * 255).round() << 16) | ((textColor.g * 255).round() << 8) | (textColor.b * 255).round());
    notifyListeners();
  }

  /// Clear the custom color override and revert to the brand preset.
  Future<void> clearCustomColors() async {
    _customBgColor   = null;
    _customTextColor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomBg);
    await prefs.remove(_keyCustomText);
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
  }
}
