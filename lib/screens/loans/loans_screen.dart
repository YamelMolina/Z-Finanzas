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

  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;
  String? _error;

  final FocusNode _focusNode = FocusNode();
  final _shortcutKey = const SingleActivator(LogicalKeyboardKey.keyN, control: true);

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  @override
  void dispose() {
    _focusNode.dispose();
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

  Future<void> _openLoanDialog() async {
    List<Map<String, dynamic>> clients = [];
    List<Map<String, dynamic>> collectors = [];
    try {
      clients = await _clientService.getClients();
      collectors = await _collectorService.getCollectors(); // Cargamos cobradores
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
              title: Text('Nuevo Préstamo', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
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
                      // DROPDOWN DE COBRADOR (Opcional)
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
                          prefixStyle: GoogleFonts.inter(color: zBlue, fontWeight: FontWeight.bold),
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
                      
                      // PROGRAMAMOS LA NOTIFICACIÓN
                      final clientName = clients.firstWhere((c) => c['id'] == selectedClientId)['full_name'];
                      int daysToAdd = 1;
                      if (frequency == 'semanal') daysToAdd = 7;
                      if (frequency == 'quincenal') daysToAdd = 15;
                      if (frequency == 'mensual') daysToAdd = 30;
                      
                      final dueDate = DateTime.now().add(Duration(days: daysToAdd, hours: 9)); // Notifica a las 9 AM
                      
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
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return CallbackShortcuts(
      bindings: { _shortcutKey: _openLoanDialog },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Préstamos', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
            actions: [
              IconButton(tooltip: 'Actualizar', onPressed: _loadLoans, icon: const Icon(Icons.refresh_rounded)),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _loading
                  ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                  : _error != null
                      ? Center(key: const ValueKey('error'), child: Text('Error: $_error'))
                      : _loans.isEmpty
                          ? Center(
                              key: const ValueKey('empty'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text('No hay préstamos registrados', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('Presiona Ctrl + N para crear uno nuevo', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('list'),
                              padding: const EdgeInsets.all(24),
                              itemCount: _loans.length,
                              itemBuilder: (context, index) {
                                final loan = _loans[index];
                                final clientName = loan['clients']?['full_name'] ?? 'Cliente desconocido';
                                final collectorName = loan['collectors']?['full_name']; // <-- COBRADOR
                                final amount = CurrencyUtils.formatMoney(loan['amount']);
                                final total = CurrencyUtils.formatMoney(loan['total_to_pay']);
                                final installments = loan['installments'];
                                final freq = loan['frequency'];
                                final status = loan['status'];
                                final isActive = status == 'activo';
                                final isOverdue = _isOverdue(loan);

                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 300 + (index * 100)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(opacity: value, child: child),
                                    );
                                  },
                                  child: Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isOverdue ? Colors.red : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                                    ),
                                    color: isOverdue ? Colors.red.withOpacity(0.05) : cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 50, height: 50,
                                                decoration: BoxDecoration(
                                                  color: isOverdue ? Colors.red.withOpacity(0.2) : (isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Icon(Icons.account_balance_rounded, color: isOverdue ? Colors.red : (isActive ? Colors.green : Colors.grey)),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(clientName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                                                    const SizedBox(height: 4),
                                                    Text('Prestado: \$$amount  •  Total: \$$total', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                                                    const SizedBox(height: 4),
                                                    // MOSTRAMOS EL COBRADOR SI TIENE
                                                    if (collectorName != null)
                                                      Text('Cobrador: $collectorName', style: GoogleFonts.inter(fontSize: 12, color: zBlue, fontWeight: FontWeight.w500)),
                                                    Text('$installments cuotas ($freq)', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isOverdue ? Colors.red.withOpacity(0.2) : (isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  isOverdue ? 'EN MORA' : status.toUpperCase(),
                                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : (isActive ? Colors.green : Colors.grey)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(height: 16),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            InkWell(
                                              onTap: () => _sendWhatsApp(loan),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.chat_bubble_outline, color: isOverdue ? Colors.red : Colors.green, size: 18),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      isOverdue ? 'Cobrar Mora por WhatsApp' : 'Enviar recordatorio por WhatsApp', 
                                                      style: GoogleFonts.inter(color: isOverdue ? Colors.red : Colors.green, fontWeight: FontWeight.w600, fontSize: 13)
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLoanDialog,
            backgroundColor: zBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: Text('Nuevo Préstamo', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}