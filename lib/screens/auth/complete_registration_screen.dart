
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../main.dart';
import '../home/home_screen.dart'; // <-- Importante para ir al inicio

class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({super.key});

  @override
  State<CompleteRegistrationScreen> createState() => _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState extends State<CompleteRegistrationScreen> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _finishRegistration() async {
    final name = _nameController.text.trim();
    final company = _companyController.text.trim();

    if (name.isEmpty || company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Llamamos al servicio que creará el perfil y la empresa en Supabase
      await _auth.completeRegistration(name: name, companyName: company);
      
      if (!mounted) return;
      
      // Si todo sale bien, nos vamos directo a la pantalla principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      
      // Mostramos el error exacto si algo falla en la base de datos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.business_center_outlined, size: 50, color: zBlue),
                  const SizedBox(height: 16),
                  const Text(
                    'Un último paso',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: zText),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para continuar, dinos tu nombre y el nombre de tu empresa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: zMuted),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _companyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de tu empresa',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _finishRegistration,
                      child: _loading
                          ? const SizedBox(
                              height: 20, 
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Finalizar registro'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => _auth.logout(),
                    child: const Text('Cerrar sesión', style: TextStyle(color: zMuted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}