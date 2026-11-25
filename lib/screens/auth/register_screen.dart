import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final company = _company.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty || company.isEmpty || email.isEmpty || password.isEmpty) {
      _message('Completa todos los campos.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.register(name: name, email: email, password: password, companyName: company);
      
      if (!mounted) return;
      if (_auth.currentUser != null) {
        _message('¡Cuenta creada exitosamente!');
        Navigator.pop(context);
      } else {
        _message('Revisa tu correo para confirmar tu cuenta.');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _message('Error: ${e.message}', error: true);
    } on PostgrestException catch (e) {
      _message('Error de base de datos: ${e.message}', error: true);
    } catch (e) {
      _message('Error inesperado: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: zNavy.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: zBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: zBlue, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text('Crea tu cuenta', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: zNavy)),
                    const SizedBox(height: 8),
                    Text('Comienza a gestionar tu negocio hoy mismo.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: zMuted)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _company,
                      decoration: const InputDecoration(labelText: 'Nombre de la empresa', prefixIcon: Icon(Icons.business_outlined)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: zMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Registrarme'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}