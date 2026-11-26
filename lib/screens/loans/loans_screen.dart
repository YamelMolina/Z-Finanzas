import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/loan_service.dart';
import '../../services/client_service.dart';
import '../../services/collector_service.dart';
import '../../services/notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../main.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LoanService _loanService = LoanService();
  final ClientService _clientService = ClientService();
  final CollectorService _collectorService = CollectorService();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Todos';

  final FocusNode _focusNode = FocusNode();
  final _shortcutKey = const SingleActivator(LogicalKeyboardKey.keyN, control: true);

  @override
  void initState() {
    super.initState();
    _loadLoans();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _loanService.getLoans();
      if (!mounted) return;
      setState(() { _loans = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredLoans {
    final search = _searchController.text.trim().toLowerCase();
    return _loans.where((loan) {
      final clientName = (loan['clients']?['full_name'] ?? '').toString().toLowerCase();
      final code = loan['id'].toString().substring(0, 6).toLowerCase();
      final matchesSearch = clientName.contains(search) || code.contains(search);
      
      final status = loan['status'] ?? 'activo';
      final matchesFilter = _filter == 'Todos' || 
                            (_filter == 'Activos' && status == 'activo') ||
                            (_filter == 'Finalizados' && status == 'pagado') ||
                            (_filter == 'Cancelados' && status == 'cancelado');
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isOverdue(Map<String, dynamic> loan) {
    if (loan['status'] != 'activo') return false;
    final startDate = DateTime.parse(loan['created_at']).toLocal();
    final installments = loan['installments'] as int;
    final frequency = loan['frequency'];
    
    int daysMultiplier = 1;
    if (frequency == 'semanal') daysMultiplier = 7;
    if (frequency == 'quincenal') daysMultiplier = 15;
    if (frequency == 'mensual') daysMultiplier = 30;

    final totalDays = installments * daysMultiplier;
    final dueDate = startDate.add(Duration(days: totalDays));
    
    return DateTime.now().isAfter(dueDate);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _sendWhatsApp(Map<String, dynamic> loan) async {
    final clientName = loan['clients']?['full_name'] ?? 'Cliente';
    final phone = loan['clients']?['phone'] ?? '';
    final total = CurrencyUtils.formatMoney(loan['total_to_pay']);
    final isOverdue = _isOverdue(loan);

    if (phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El cliente no tiene teléfono registrado.')));
      return;
    }

    final cleanPhone = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final message = isOverdue 
      ? 'Hola $clientName, te saludamos de Z Finances. Notamos que tu préstamo por \$$total se encuentra en MORA. Por favor, comunícate con nosotros para regularizar tu pago.'
      : 'Hola $clientName, te saluda tu prestamista de Z Finances. Te recuerdo amablemente tu compromiso de pago por un total de \$$total. ¡Gracias!';
      
    final url = Uri.parse('https://wa.me/57$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.')));
    }
  }

  // MENÚ DE OPCIONES AL TOCAR LA TARJETA
  void _showLoanOptions(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Opciones del Préstamo', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: Text('Registrar Cobro', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ve a la pestaña de Cobros para registrar el pago.')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                title: Text('Enviar Recordatorio WhatsApp', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _sendWhatsApp(loan);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: Text('Cancelar Préstamo', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función de cancelación en desarrollo.')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLoanDialog() async {
    List<Map<String, dynamic>> clients = [];
    List<Map<String, dynamic>> collectors = [];
    try {
      clients = await _clientService.getClients();
      collectors = await _collectorService.getCollectors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      return;
    }

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero debes registrar un cliente.')));
      return;
    }

    String? selectedClientId = clients.first['id'];
    String? selectedCollectorId = collectors.isNotEmpty ? collectors.first['id'] : null;
    final amountCtrl = TextEditingController();
    final interestCtrl = TextEditingController(text: '0');
    final installmentsCtrl = TextEditingController(text: '1');
    String frequency = 'semanal';
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Nuevo Préstamo', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedClientId,
                        decoration: InputDecoration(
                          labelText: 'Cliente',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: clients.map((c) => DropdownMenuItem(
                          value: c['id'].toString(), 
                          child: Text(c['full_name'] ?? 'Sin nombre')
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedClientId = val),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCollectorId,
                        decoration: InputDecoration(
                          labelText: 'Cobrador Asignado (Opcional)',
                          prefixIcon: const Icon(Icons.route),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                          ...collectors.map((c) => DropdownMenuItem(
                            value: c['id'].toString(), 
                            child: Text(c['full_name'] ?? 'Sin nombre')
                          ))
                        ],
                        onChanged: (val) => setDialogState(() => selectedCollectorId = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Monto Prestado',
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.poppins(color: zBlue, fontWeight: FontWeight.bold),
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: interestCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Interés (%)',
                                prefixIcon: const Icon(Icons.percent),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: installmentsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cuotas',
                                prefixIcon: const Icon(Icons.format_list_numbered),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: frequency,
                        decoration: InputDecoration(
                          labelText: 'Frecuencia',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['diario', 'semanal', 'quincenal', 'mensual'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
                        onChanged: (val) => setDialogState(() => frequency = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: zBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: saving ? null : () async {
                    final cleanAmountStr = amountCtrl.text.replaceAll('.', '');
                    final amount = double.tryParse(cleanAmountStr) ?? 0;
                    final interest = double.tryParse(interestCtrl.text) ?? 0;
                    final installments = int.tryParse(installmentsCtrl.text) ?? 1;

                    if (amount <= 0 || installments <= 0 || selectedClientId == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Verifica los datos.')));
                      return;
                    }

                    final totalToPay = amount + (amount * (interest / 100));

                    setDialogState(() => saving = true);
                    try {
                      await _loanService.createLoan(
                        clientId: selectedClientId!,
                        amount: amount,
                        interestRate: interest,
                        totalToPay: totalToPay,
                        installments: installments,
                        frequency: frequency,
                        collectorId: selectedCollectorId,
                      );
                      
                      final clientName = clients.firstWhere((c) => c['id'] == selectedClientId)['full_name'];
                      int daysToAdd = 1;
                      if (frequency == 'semanal') daysToAdd = 7;
                      if (frequency == 'quincenal') daysToAdd = 15;
                      if (frequency == 'mensual') daysToAdd = 30;
                      
                      final dueDate = DateTime.now().add(Duration(days: daysToAdd, hours: 9));
                      
                      await NotificationService.scheduleLoanReminder(
                        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                        clientName: clientName,
                        amount: totalToPay / installments,
                        scheduledDate: dueDate,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadLoans();
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: saving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Guardar Préstamo', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : zNavy;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return CallbackShortcuts(
      bindings: { _shortcutKey: _openLoanDialog },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Column(
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
                      Text('Préstamos', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                      Text('${_loans.length} registrados', style: GoogleFonts.poppins(fontSize: 13, color: zMuted)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openLoanDialog,
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
                  hintText: 'Buscar por cliente o código...',
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
                  _buildChip('Todos', _filter == 'Todos', () => setState(() => _filter = 'Todos'), isDark),
                  _buildChip('Activos', _filter == 'Activos', () => setState(() => _filter = 'Activos'), isDark),
                  _buildChip('Finalizados', _filter == 'Finalizados', () => setState(() => _filter = 'Finalizados'), isDark),
                  _buildChip('Cancelados', _filter == 'Cancelados', () => setState(() => _filter = 'Cancelados'), isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _filteredLoans.isEmpty
                          ? Center(child: Text('No hay préstamos registrados', style: GoogleFonts.poppins(color: zMuted)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredLoans.length,
                              itemBuilder: (context, index) {
                                final loan = _filteredLoans[index];
                                final clientName = loan['clients']?['full_name'] ?? 'Cliente desconocido';
                                final amount = CurrencyUtils.formatMoney(loan['amount']);
                                final total = CurrencyUtils.formatMoney(loan['total_to_pay']);
                                final installments = loan['installments'];
                                final paidInstallments = 0; 
                                final pendingAmount = loan['total_to_pay']; 
                                final freq = loan['frequency'];
                                final status = loan['status'];
                                final code = loan['id'].toString().substring(0, 6).toUpperCase();
                                final isOverdue = _isOverdue(loan);
                                
                                final progress = paidInstallments / installments;

                                return GestureDetector(
                                  onTap: () => _showLoanOptions(loan), // ABRE EL MENÚ AL TOCAR
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isOverdue ? Colors.red : borderColor),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(clientName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                                Text('Z-$code • ${freq[0].toUpperCase()}${freq.substring(1)}', style: GoogleFonts.poppins(fontSize: 12, color: zMuted)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                                  child: Row(
                                                    children: [
                                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: isOverdue ? Colors.red : Colors.green, shape: BoxShape.circle)),
                                                      const SizedBox(width: 4),
                                                      Text('0 días', style: GoogleFonts.poppins(fontSize: 10, color: isOverdue ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                                  child: Text('Activo', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.green),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _sendWhatsApp(loan),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        
                                        Row(
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 55, height: 55,
                                                  child: CircularProgressIndicator(
                                                    value: progress,
                                                    strokeWidth: 6,
                                                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                                    color: zBlue,
                                                    strokeCap: StrokeCap.round,
                                                  ),
                                                ),
                                                Text('${(progress * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                                              ],
                                            ),
                                            const SizedBox(width: 20),
                                            
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildDataColumn('CAPITAL', '\$$amount', textColor),
                                                  _buildDataColumn('CUOTA', '\$$total', textColor),
                                                  _buildDataColumn('PENDIENTE', '\$$pendingAmount', Colors.orange),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Cuotas: $paidInstallments/$installments (${installments - paidInstallments} pend.)', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                                            Text('Próxima: ${_formatDate(loan['created_at'])}', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                                          ],
                                        )
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
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? zBlue : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? zBlue : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : (isDark ? Colors.white : zNavy), fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDataColumn(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: zMuted)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}