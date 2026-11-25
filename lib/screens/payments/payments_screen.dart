import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_service.dart';
import '../../services/pdf_service.dart';
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

  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _paymentService.getPayments();
      if (!mounted) return;
      setState(() { _payments = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
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

  Future<void> _openPaymentDialog() async {
    List<Map<String, dynamic>> activeLoans = [];
    try {
      activeLoans = await _paymentService.getActiveLoans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      return;
    }

    if (activeLoans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay préstamos activos para cobrar.')));
      return;
    }

    Map<String, dynamic>? selectedLoan = activeLoans.first;
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
              title: Text('Registrar Cobro', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedLoan!['id'].toString(),
                        decoration: InputDecoration(
                          labelText: 'Préstamo a Cobrar',
                          prefixIcon: const Icon(Icons.account_balance),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: activeLoans.map((l) {
                          final clientName = l['clients']?['full_name'] ?? 'Desconocido';
                          final total = CurrencyUtils.formatMoney(l['total_to_pay']);
                          return DropdownMenuItem(
                            value: l['id'].toString(),
                            child: Text('$clientName - Total: \$$total', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedLoan = activeLoans.firstWhere((l) => l['id'].toString() == val);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (selectedLoan != null)
                        Text(
                          'Cuota sugerida: \$${CurrencyUtils.formatMoney(selectedLoan!['total_to_pay'] / selectedLoan!['installments'])}',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Monto a Cobrar',
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.inter(color: zBlue, fontWeight: FontWeight.bold),
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

                    if (amount <= 0 || selectedLoan == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido.')));
                      return;
                    }

                    setDialogState(() => saving = true);
                    try {
                      await _paymentService.createPayment(
                        loanId: selectedLoan!['id'].toString(),
                        clientId: selectedLoan!['client_id'].toString(),
                        amount: amount,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadPayments();
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: saving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Guardar Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Cobros', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _loadPayments, icon: const Icon(Icons.refresh_rounded)),
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
                  : _payments.isEmpty
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments_outlined, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No hay cobros registrados', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          key: const ValueKey('list'),
                          padding: const EdgeInsets.all(24),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            final clientName = payment['clients']?['full_name'] ?? 'Cliente desconocido';
                            final amount = CurrencyUtils.formatMoney(payment['amount']);
                            final date = payment['payment_date'].toString().substring(0, 10);

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Opacity(opacity: value, child: child));
                              },
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20), 
                                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                                ),
                                color: cardColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                        child: const Icon(Icons.payments, color: Colors.green),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(clientName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Fecha: $date', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('\$$amount', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                          const SizedBox(height: 8),
                                          // BOTÓN DE GENERAR PDF
                                          InkWell(
                                            onTap: () => _showPdf(payment),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: zBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.picture_as_pdf, color: zBlue, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text('Recibo', style: GoogleFonts.inter(color: zBlue, fontWeight: FontWeight.w600, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
        onPressed: _openPaymentDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text('Registrar Cobro', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }
}