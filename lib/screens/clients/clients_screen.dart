import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/client_service.dart';
import '../../main.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _service = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getClients();
      if (!mounted) return;
      setState(() { _clients = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredClients {
    final search = _searchController.text.trim().toLowerCase();
    return _clients.where((client) {
      final name = (client['full_name'] ?? '').toString().toLowerCase();
      final document = (client['document_number'] ?? '').toString().toLowerCase();
      final phone = (client['phone'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(search) || document.contains(search) || phone.contains(search);
      final active = client['active'] == true;
      final matchesFilter = _filter == 'Todos' || (_filter == 'Activos' && active) || (_filter == 'Inactivos' && !active);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openClientDialog({Map<String, dynamic>? client}) async {
    final isEditing = client != null;
    final nameController = TextEditingController(text: client?['full_name']?.toString() ?? '');
    final documentController = TextEditingController(text: client?['document_number']?.toString() ?? '');
    final phoneController = TextEditingController(text: client?['phone']?.toString() ?? '');
    final addressController = TextEditingController(text: client?['address']?.toString() ?? '');
    final notesController = TextEditingController(text: client?['notes']?.toString() ?? '');

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
              title: Text(isEditing ? 'Editar cliente' : 'Nuevo cliente', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(nameController, 'Nombre completo', Icons.person_outline, required: true),
                        _field(documentController, 'Número de documento', Icons.badge_outlined),
                        _field(phoneController, 'Teléfono', Icons.phone_outlined),
                        _field(addressController, 'Dirección', Icons.location_on_outlined),
                        _field(notesController, 'Observaciones', Icons.notes_outlined, maxLines: 3),
                      ],
                    ),
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
                      if (isEditing) {
                        await _service.updateClient(
                          id: client['id'].toString(),
                          fullName: nameController.text,
                          documentNumber: documentController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          notes: notesController.text,
                        );
                      } else {
                        await _service.createClient(
                          fullName: nameController.text,
                          documentNumber: documentController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          notes: notesController.text,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadClients();
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: saving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text(isEditing ? 'Guardar' : 'Registrar', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required ? (value) => (value == null || value.trim().isEmpty) ? 'Obligatorio' : null : null,
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> client) async {
    final current = client['active'] == true;
    try {
      await _service.setClientActive(id: client['id'].toString(), active: !current);
      _loadClients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE7ECF3);

    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _loadClients, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _loading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : _error != null
                  ? Center(key: const ValueKey('error'), child: Text('Error: $_error'))
                  : Column(
                      key: const ValueKey('content'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, documento o teléfono...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(child: Text('No se encontraron clientes', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final client = filtered[index];
                                    final active = client['active'] == true;
                                    final name = (client['full_name'] ?? 'Sin nombre').toString();

                                    return Card(
                                      color: cardColor,
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFDBEAFE),
                                          foregroundColor: zBlue,
                                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : zNavy)),
                                        subtitle: Text(client['phone'] ?? 'Sin teléfono', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54)),
                                        trailing: PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54),
                                          onSelected: (value) {
                                            if (value == 'edit') _openClientDialog(client: client);
                                            if (value == 'toggle') _toggleActive(client);
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                            PopupMenuItem(value: 'toggle', child: Text(active ? 'Desactivar' : 'Activar')),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientDialog(),
        backgroundColor: zBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Nuevo cliente', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }
}