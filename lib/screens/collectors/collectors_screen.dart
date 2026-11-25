import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/collector_service.dart';
import '../../main.dart';

class CollectorsScreen extends StatefulWidget {
  const CollectorsScreen({super.key});

  @override
  State<CollectorsScreen> createState() => _CollectorsScreenState();
}

class _CollectorsScreenState extends State<CollectorsScreen> {
  final CollectorService _service = CollectorService();

  List<Map<String, dynamic>> _collectors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollectors();
  }

  Future<void> _loadCollectors() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getCollectors();
      if (!mounted) return;
      setState(() { _collectors = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCollectorDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Nuevo Cobrador', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: zBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  onPressed: saving ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => saving = true);
                    try {
                      await _service.createCollector(fullName: nameController.text, phone: phoneController.text);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadCollectors();
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: saving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> collector) async {
    final current = collector['active'] == true;
    try {
      await _service.setCollectorActive(id: collector['id'].toString(), active: !current);
      _loadCollectors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cobradores', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _loadCollectors, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _collectors.isEmpty
                    ? Center(child: Text('No hay cobradores registrados.', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _collectors.length,
                        itemBuilder: (context, index) {
                          final c = _collectors[index];
                          final active = c['active'] == true;
                          final name = c['full_name'] ?? 'Sin nombre';
                          final phone = c['phone'] ?? 'Sin teléfono';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
                            color: cardColor,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: active ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                child: Icon(Icons.route, color: active ? zBlue : Colors.grey),
                              ),
                              title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              subtitle: Text(phone, style: GoogleFonts.inter(color: Colors.grey)),
                              trailing: Switch(
                                value: active,
                                activeColor: zBlue,
                                onChanged: (_) => _toggleActive(c),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCollectorDialog,
        backgroundColor: zBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Nuevo Cobrador', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }
}