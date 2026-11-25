import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();
  final AuthService _auth = AuthService();
  
  bool _loading = true;
  String? _companyId;
  String _companyName = '';
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await _service.getCompanyInfo();
      if (!mounted) return;
      setState(() {
        _companyId = info['id'];
        _companyName = info['name'];
        _nameController.text = _companyName;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveCompanyName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _companyName) return;

    setState(() => _saving = true);
    try {
      await _service.updateCompanyName(_companyId!, newName);
      if (!mounted) return;
      setState(() {
        _companyName = newName;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado correctamente.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Perfil de la Empresa', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Nombre de la empresa', prefixIcon: Icon(Icons.store)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _saving ? null : _saveCompanyName,
                                child: _saving 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Guardar Cambios'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Apariencia', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          ),
                          child: SwitchListTile(
                            title: Text('Modo Oscuro', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            subtitle: Text('Cambia los colores de la aplicación', style: GoogleFonts.inter(fontSize: 12)),
                            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.yellow : Colors.orange),
                            value: isDark,
                            activeColor: zBlue,
                            onChanged: (value) {
                              ThemeService.toggleTheme(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Cuenta', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.email, color: zMuted),
                                title: const Text('Correo Electrónico'),
                                subtitle: Text(email),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.logout, color: Colors.red),
                                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                onTap: () => _auth.logout(),
                              ),
                            ],
                          ),
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