import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_service.dart';
import '../../services/pdf_service.dart';
import '../../services/loan_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../main.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final PdfService _pdfService = PdfService();
  final LoanService _loanService = LoanService();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Todos'; // 'Solo de hoy' o 'Todos'

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final loans = await _loanService.getLoans();
      final payments = await _paymentService.getPayments();
      if (!mounted) return;
      setState(() {
        // Solo mostramos préstamos activos en la pantalla de cobros
        _loans = loans.where((l) => l['status'] == 'activo').toList();
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Cálculos del día
  double get _recaudadoHoy {
    final today = DateTime.now();
    double total = 0;
    for (var p in _payments) {
      final date = DateTime.parse(p['payment_date']).toLocal();
      if (date.day == today.day && date.month == today.month && date.year == today.year) {
        total += (p['amount'] as num).toDouble();
      }
    }
    return total;
  }

  // Simulamos datos para el diseño como en tu imagen
  int get _pendientesCount => _loans.length > 36 ? 36 : _loans.length; 
  int get _pagaronCount => 24; 
  int get _noHoyCount => 27;

  List<Map<String, dynamic>> get _filteredLoans {
    final search = _searchController.text.trim().toLowerCase();
    return _loans.where((loan) {
      final clientName = (loan['clients']?['full_name'] ?? '').toString().toLowerCase();
      final code = loan['id'].toString().substring(0, 6).toLowerCase();
      return clientName.contains(search) || code.contains(search);
    }).toList();
  }

  void _showPdf(Map<String, dynamic> payment) {
    final clientName = payment['clients']?['full_name'] ?? 'Cliente';
    final amount = CurrencyUtils.formatMoney(payment['amount']);
    final date = payment['payment_date'].toString().substring(0, 10);
    final id = payment['id'].toString();

    _pdfService.generateAndShowReceipt(
      clientName: clientName,
      amount: amount,
      date: date,
      paymentId: id,
    );
  }

  Future<void> _openPaymentDialog(Map<String, dynamic> loan) async {
    final amountCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Registrar Cobro', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cliente: ${loan['clients']?['full_name']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (loan != null)
                        Text(
                          'Cuota sugerida: \$${CurrencyUtils.formatMoney(loan['total_to_pay'] / loan['installments'])}',
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Monto a Cobrar',
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.poppins(color: zBlue, fontWeight: FontWeight.bold),
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: saving ? null : () async {
                    final cleanAmountStr = amountCtrl.text.replaceAll('.', '');
                    final amount = double.tryParse(cleanAmountStr) ?? 0;

                    if (amount <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido.')));
                      return;
                    }

                    setDialogState(() => saving = true);
                    try {
                      await _paymentService.createPayment(
                        loanId: loan['id'].toString(),
                        clientId: loan['client_id'].toString(),
                        amount: amount,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadData(); // Recargamos todo
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: saving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text('Guardar Cobro', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cobrar', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                Text('Resumen del día y estado de cada cliente', style: GoogleFonts.poppins(fontSize: 13, color: zMuted)),
              ],
            ),
          ),

          // TARJETA AZUL (RECAUDADO HOY)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0043CE), Color(0xFF0066FF), Color(0xFF00A3FF)],
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0066FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RECAUDADO HOY', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('\$${CurrencyUtils.formatMoney(_recaudadoHoy)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Esperado \$ 369.588', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      Text('100%', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // BARRA DE PROGRESO
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0, // Aquí puedes poner la lógica real
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TRES TARJETAS DE ESTADO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildStatusCard('PENDIENTES', '$_pendientesCount', Icons.access_time, const Color(0xFFFFF7E6), Colors.orange),
                const SizedBox(width: 10),
                _buildStatusCard('PAGARON', '$_pagaronCount', Icons.check_circle_outline, const Color(0xFFE8F5E9), Colors.green),
                const SizedBox(width: 10),
                _buildStatusCard('NO HOY', '$_noHoyCount', Icons.calendar_today, const Color(0xFFE3F2FD), Colors.blue),
              ],
            ),
          ),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente o código...',
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

          // FILTRO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sort, color: zMuted, size: 18),
                    const SizedBox(width: 6),
                    Text('Orden: Pendiente hoy -> Pagó hoy', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildToggleBtn('Solo de hoy', _filter == 'Solo de hoy', () => setState(() => _filter = 'Solo de hoy')),
                      _buildToggleBtn('Todos', _filter == 'Todos', () => setState(() => _filter = 'Todos')),
                    ],
                  ),
                )
              ],
            ),
          ),

          // LISTA DE COBROS
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _filteredLoans.length,
            itemBuilder: (context, index) {
              final loan = _filteredLoans[index];
              final clientName = loan['clients']?['full_name'] ?? 'Cliente';
              final code = loan['id'].toString().substring(0, 6).toUpperCase();
              final amount = CurrencyUtils.formatMoney(loan['total_to_pay'] / loan['installments']);
              final balance = CurrencyUtils.formatMoney(loan['total_to_pay']);
              final isOverdue = index % 2 == 0; // Simulando mora para el diseño

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // AVATAR
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: zBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text(clientName[0].toUpperCase(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: zBlue))),
                    ),
                    const SizedBox(width: 16),
                    // DATOS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clientName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          Text('Z-$code', style: GoogleFonts.poppins(fontSize: 12, color: zMuted)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 12, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text('Pendiente hoy', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text('267 días atraso', style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          )
                        ],
                      ),
                    ),
                    // MONTOS
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$$amount', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: zBlue)),
                        Text('Saldo: \$$balance', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openPaymentDialog(loan),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                            child: Text('Cobrar', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 100), // Espacio para que no tape la barra inferior
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(count, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? zBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : zMuted)),
      ),
    );
  }
}