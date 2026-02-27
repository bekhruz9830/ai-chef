import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> setDark(bool val) async {
    _isDark = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
    notifyListeners();
  }
}
