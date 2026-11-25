import 'package:flutter/material.dart';

import '../../services/client_service.dart';

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

  static const Color navy = Color(0xFF0B1220);
  static const Color blue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF4F7FC);

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.getClients();

      if (!mounted) return;

      setState(() {
        _clients = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredClients {
    final search = _searchController.text.trim().toLowerCase();

    return _clients.where((client) {
      final name = (client['full_name'] ?? '').toString().toLowerCase();
      final document = (client['document_number'] ?? '')
          .toString()
          .toLowerCase();
      final phone = (client['phone'] ?? '').toString().toLowerCase();

      final matchesSearch =
          name.contains(search) ||
          document.contains(search) ||
          phone.contains(search);

      final active = client['active'] == true;

      final matchesFilter =
          _filter == 'Todos' ||
          (_filter == 'Activos' && active) ||
          (_filter == 'Inactivos' && !active);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openClientDialog({Map<String, dynamic>? client}) async {
    final isEditing = client != null;

    final nameController = TextEditingController(
      text: client?['full_name']?.toString() ?? '',
    );
    final documentController = TextEditingController(
      text: client?['document_number']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: client?['phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: client?['address']?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: client?['notes']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Editar cliente' : 'Nuevo cliente',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          nameController,
                          'Nombre completo',
                          Icons.person_outline,
                          required: true,
                        ),
                        _field(
                          documentController,
                          'Número de documento',
                          Icons.badge_outlined,
                        ),
                        _field(
                          phoneController,
                          'Teléfono',
                          Icons.phone_outlined,
                        ),
                        _field(
                          addressController,
                          'Dirección',
                          Icons.location_on_outlined,
                        ),
                        _field(
                          notesController,
                          'Observaciones',
                          Icons.notes_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: blue),
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

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

                            await _loadClients();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Cliente actualizado correctamente.'
                                      : 'Cliente registrado correctamente.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('No se pudo guardar: $e')),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Guardar cambios' : 'Registrar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: background,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es obligatorio.';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> client) async {
    final current = client['active'] == true;

    try {
      await _service.setClientActive(
        id: client['id'].toString(),
        active: !current,
      );

      await _loadClients();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(current ? 'Cliente desactivado.' : 'Cliente activado.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;
    final activeCount = _clients
        .where((client) => client['active'] == true)
        .length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        title: const Text(
          'Clientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loadClients,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorView()
            : RefreshIndicator(
                onRefresh: _loadClients,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _header(activeCount),
                    const SizedBox(height: 22),
                    _searchBox(),
                    const SizedBox(height: 14),
                    _filters(),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      _emptyView()
                    else
                      ...filtered.map(_clientCard),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientDialog(),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
      ),
    );
  }

  Widget _header(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navy, Color(0xFF1D3B70)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de clientes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Administra la información de tus clientes.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.groups_rounded, color: Colors.white, size: 42),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, documento o teléfono...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 8,
      children: ['Todos', 'Activos', 'Inactivos'].map((filter) {
        return ChoiceChip(
          label: Text(filter),
          selected: _filter == filter,
          onSelected: (_) => setState(() => _filter = filter),
          selectedColor: const Color(0xFFDBEAFE),
          labelStyle: TextStyle(
            color: _filter == filter ? blue : navy,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _clientCard(Map<String, dynamic> client) {
    final active = client['active'] == true;
    final name = (client['full_name'] ?? 'Sin nombre').toString();
    final document = (client['document_number'] ?? '').toString();
    final phone = (client['phone'] ?? '').toString();

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7ECF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFDBEAFE),
              foregroundColor: blue,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (document.isNotEmpty)
                    Text(
                      'Documento: $document',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  if (phone.isNotEmpty)
                    Text(phone, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(
                    active ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: active ? Colors.green.shade700 : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openClientDialog(client: client);
                } else if (value == 'toggle') {
                  _toggleActive(client);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(active ? 'Desactivar' : 'Activar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 55, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron clientes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra un cliente o cambia los filtros de búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar los clientes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadClients,
              child: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }
}
