import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_registration_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';

// NUEVA PALETA DE COLORES BASADA EN LA IMAGEN
const Color zBlue = Color(0xFF0056FF); // Azul vibrante principal
const Color zNavy = Color(0xFF0F172A); // Azul oscuro para textos
const Color zBackground = Color(0xFFF5F7FA); // Fondo gris muy claro
const Color zText = Color(0xFF1E293B);
const Color zMuted = Color(0xFF64748B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    runApp(const ZFinancesApp());
  } catch (e) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Error:\n$e', style: const TextStyle(color: Colors.red)))),
    ));
  }
}

class ZFinancesApp extends StatelessWidget {
  const ZFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: zBlue, 
        primary: zBlue, 
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: zBackground,
      // Usamos la fuente Poppins que se parece mucho a la de la imagen
      textTheme: ThemeData.light().textTheme.apply(fontFamily: GoogleFonts.poppins().fontFamily, bodyColor: zText, displayColor: zText),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: zText, elevation: 0),
      inputDecorationTheme: _inputTheme(Colors.white, Colors.grey.shade200),
      elevatedButtonTheme: _buttonTheme(),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: zBlue, 
        primary: zBlue, 
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: GoogleFonts.poppins().fontFamily, bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: _inputTheme(const Color(0xFF1E293B), Colors.grey.shade700),
      elevatedButtonTheme: _buttonTheme(),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Z Finances',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const AuthGate(),
        );
      },
    );
  }

  InputDecorationTheme _inputTheme(Color fillColor, Color borderColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: zMuted, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: zBlue, width: 1.5)),
    );
  }

  ElevatedButtonThemeData _buttonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: zBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _hasCompany() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final response = await Supabase.instance.client.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    return response != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const LoginScreen();

        return FutureBuilder<bool>(
          future: _hasCompany(),
          builder: (context, companySnapshot) {
            if (companySnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (companySnapshot.data == false) return const CompleteRegistrationScreen(); 
            return const HomeScreen();
          },
        );
      },
    );
  }
}