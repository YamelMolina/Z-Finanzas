import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/cash_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../main.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final CashService _cashService = CashService();
  
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadCash();
  }

  Future<void> _loadCash() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _cashService.getDailySummary();
      if (!mounted) return;
      setState(() { _summary = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _closeRegister() async {
    final balance = _summary!['balance'] as double;
    final income = _summary!['total_payments'] as double;
    final expenses = _summary!['total_loans'] as double;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Cerrar Caja?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Se guardará un registro con el balance del día. No podrás deshacer esta acción.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, cerrar caja')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _closing = true);
    try {
      await _cashService.closeRegister(totalIncome: income, totalExpenses: expenses, balance: balance);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caja cerrada exitosamente.'), backgroundColor: Colors.green));
      _loadCash(); // Recargar (el balance seguirá ahí, pero ya está guardado)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar caja: $e')));
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : zNavy;

    return Scaffold(
      appBar: AppBar(
        title: Text('Caja Diaria', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _loadCash, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : RefreshIndicator(
                    onRefresh: _loadCash,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen de hoy', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 16),
                          _buildSummaryCards(cardColor, borderColor, textColor),
                          const SizedBox(height: 24),
                          
                          // BOTÓN DE CIERRE DE CAJA
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: (_closing || (_summary!['total_loans'] == 0 && _summary!['total_payments'] == 0)) ? null : _closeRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                elevation: 0,
                              ),
                              icon: _closing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Icon(Icons.lock_outline),
                              label: Text('CERRAR CAJA DEL DÍA', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 32),
                          Text('Movimientos de hoy', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 16),
                          _buildTransactionList(cardColor, borderColor),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCards(Color cardColor, Color borderColor, Color textColor) {
    final balance = _summary!['balance'] as double;
    final isPositive = balance >= 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _card(
                title: 'Ingresos (Cobros)',
                amount: CurrencyUtils.formatMoney(_summary!['total_payments']),
                icon: Icons.arrow_downward_rounded,
                color: Colors.green,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _card(
                title: 'Egresos (Préstamos)',
                amount: CurrencyUtils.formatMoney(_summary!['total_loans']),
                icon: Icons.arrow_upward_rounded,
                color: Colors.red,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isPositive ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E3A8A) : zNavy) : Colors.red.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance Neto del Día', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 8),
              Text('\$${CurrencyUtils.formatMoney(balance)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required String title, required String amount, required IconData icon, required Color color, required Color cardColor, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('\$$amount', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(Color cardColor, Color borderColor) {
    final loans = _summary!['loans'] as List<Map<String, dynamic>>;
    final payments = _summary!['payments'] as List<Map<String, dynamic>>;

    final List<Map<String, dynamic>> allTransactions = [];
    for (var l in loans) { allTransactions.add({'type': 'egreso', 'title': 'Préstamo a ${l['clients']?['full_name'] ?? 'Cliente'}', 'amount': l['amount']}); }
    for (var p in payments) { allTransactions.add({'type': 'ingreso', 'title': 'Cobro a ${p['clients']?['full_name'] ?? 'Cliente'}', 'amount': p['amount']}); }

    if (allTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No hay movimientos registrados hoy.', style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allTransactions.length,
      itemBuilder: (context, index) {
        final tx = allTransactions[index];
        final isIngreso = tx['type'] == 'ingreso';
        final amount = CurrencyUtils.formatMoney(tx['amount']);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
          color: cardColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIngreso ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              child: Icon(isIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIngreso ? Colors.green : Colors.red),
            ),
            title: Text(tx['title'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            trailing: Text(
              '${isIngreso ? '+' : '-'}\$$amount',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: isIngreso ? Colors.green : Colors.red),
            ),
          ),
        );
      },
    );
  }
}