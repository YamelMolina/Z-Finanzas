import 'package:flutter/material.dart';

class ThemeService {
  // Usamos un ValueNotifier para que toda la app escuche cuando cambiemos el tema
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}