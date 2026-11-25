import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa tu correo y contraseña.', error: true);
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Escribe un correo electrónico válido.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.login(email: email, password: password);
    } catch (e) {
      _showMessage('No fue posible iniciar sesión. Verifica tus datos.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (wide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [zNavy, Color(0xFF1E3A8A), zBlue],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50, right: -50,
                      child: Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: const Text('Z', style: TextStyle(color: zBlue, fontSize: 32, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 16),
                              Text('Z FINANCES', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2)),
                            ],
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Controla tu futuro\nfinanciero hoy.',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'La plataforma definitiva para gestionar préstamos, clientes y cobros con la elegancia que tu negocio merece.',
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide) ...[
                          const Center(
                            child: CircleAvatar(radius: 30, backgroundColor: zNavy, child: Text('Z', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(height: 40),
                        ],
                        Text('Bienvenido de nuevo', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: zNavy, letterSpacing: -1)),
                        const SizedBox(height: 8),
                        Text('Ingresa tus credenciales para continuar.', style: GoogleFonts.inter(color: zMuted, fontSize: 15)),
                        const SizedBox(height: 40),
                        
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: zMuted),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('¿Olvidaste tu contraseña?', style: GoogleFonts.inter(color: zBlue, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Iniciar Sesión'),
                        ),
                        
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('O', style: GoogleFonts.inter(color: zMuted)),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 30),

                        OutlinedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: zNavy,
                          ),
                          child: Text('Crear una cuenta nueva', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}