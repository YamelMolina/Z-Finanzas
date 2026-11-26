import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/client_service.dart';
import '../../main.dart';
import '../../core/utils/currency_formatter.dart';

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
              title: Text(isEditing ? 'Editar cliente' : 'Nuevo cliente', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                      : Text(isEditing ? 'Guardar' : 'Registrar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : zNavy;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clientes', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                  Text('${_clients.length} registrados', style: GoogleFonts.poppins(fontSize: 13, color: zMuted)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openClientDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: zBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Nuevo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, documento, teléfono...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: zMuted),
              prefixIcon: const Icon(Icons.search, color: zMuted),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildChip('Todos', true),
              _buildChip('Activos', false),
              _buildChip('Inactivos', false),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: zBlue),
              const SizedBox(width: 8),
              Text('Mantén presionado un cliente para acciones rápidas', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _filteredClients.isEmpty
                      ? Center(child: Text('No se encontraron clientes', style: GoogleFonts.poppins(color: zMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            final active = client['active'] == true;
                            final name = (client['full_name'] ?? 'Sin nombre').toString();
                            final phone = (client['phone'] ?? 'Sin teléfono').toString();
                            final mockBalance = 150000; 

                            return GestureDetector(
                              onTap: () => _openClientDialog(client: client), // ABRE EL MODAL AL TOCAR
                              onLongPress: () => _toggleActive(client), // ACTIVA/DESACTIVA AL MANTENER
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 50, height: 50,
                                          decoration: BoxDecoration(color: zBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                                          child: Center(child: Text(name[0].toUpperCase(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: zBlue))),
                                        ),
                                        if (active)
                                          Positioned(
                                            bottom: 0, right: 0,
                                            child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: cardColor, width: 2))),
                                          )
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                                child: Text(active ? 'Activo' : 'Inactivo', style: GoogleFonts.poppins(fontSize: 10, color: active ? Colors.green : Colors.grey, fontWeight: FontWeight.w600)),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, size: 14, color: zMuted),
                                              const SizedBox(width: 4),
                                              Text(phone, style: GoogleFonts.poppins(fontSize: 12, color: zMuted)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.account_balance_wallet, size: 14, color: zBlue),
                                              const SizedBox(width: 4),
                                              Text('\$${CurrencyUtils.formatMoney(mockBalance)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: zBlue)),
                                              const SizedBox(width: 4),
                                              Text('saldo activo', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.star_border_rounded, color: zMuted),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Función de favoritos próximamente'))
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? zBlue : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? zBlue : Colors.grey.shade300),
      ),
      child: Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : zNavy), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}