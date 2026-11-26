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
  String _selectedPeriod = 'Hoy';

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
        title: Text('¿Cerrar Caja?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Se guardará un registro con el balance del día. No podrás deshacer esta acción.', style: GoogleFonts.poppins()),
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
      _loadCash();
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
    final textColor = isDark ? Colors.white : zNavy;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    final totalRecaudado = _summary!['total_payments'] as double;
    final pendiente = _summary!['total_loans'] as double; // Simulando pendientes con egresos
    final movimientosCount = (_summary!['payments'] as List).length;
    final cuotasCount = (_summary!['payments'] as List).length; // Simulando cuotas

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Caja Diaria', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                    Text('Panel financiero del período', style: GoogleFonts.poppins(fontSize: 13, color: zMuted)),
                  ],
                ),
                Row(
                  children: [
                    _buildActionButton(Icons.grid_on, 'Excel', () {}),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.picture_as_pdf, 'PDF', () {}),
                  ],
                )
              ],
            ),
          ),

          // FILTROS DE TIEMPO
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildChip('Hoy', true, isDark),
                _buildChip('Ayer', false, isDark),
                _buildChip('Esta semana', false, isDark),
                _buildChip('30 días', false, isDark),
                _buildChip('Este mes', false, isDark),
                _buildChip('Mes anterior', false, isDark),
                _buildChip('Personalizado', false, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TARJETA AZUL PRINCIPAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      Text('TOTAL RECAUDADO', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('\$${CurrencyUtils.formatMoney(totalRecaudado)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // SUB TARJETAS (EFECTIVO, NEQUI, CUOTAS)
                  Row(
                    children: [
                      _subCard('EFECTIVO', totalRecaudado * 0.15), // Simulado
                      const SizedBox(width: 10),
                      _subCard('NEQUI', totalRecaudado * 0.85), // Simulado
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('CUOTAS', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('$cuotasCount', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TARJETA NARANJA (PENDIENTE)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.access_time, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PENDIENTE POR COBRAR HOY', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange)),
                        const SizedBox(height: 4),
                        Text('\$${CurrencyUtils.formatMoney(pendiente)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Recaudado hoy', style: GoogleFonts.poppins(fontSize: 11, color: zMuted)),
                      const SizedBox(height: 4),
                      Text('\$${CurrencyUtils.formatMoney(totalRecaudado)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: zNavy)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // HISTORIAL DIARIO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('HISTORIAL DIARIO', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: zMuted, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoy', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                        Text('25 de nov de 2026', style: GoogleFonts.poppins(fontSize: 12, color: zMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${CurrencyUtils.formatMoney(totalRecaudado)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 4),
                      Text('$movimientosCount mov • $cuotasCount cobros', style: GoogleFonts.poppins(fontSize: 12, color: zMuted)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: zMuted)
                ],
              ),
            ),
          ),

          // BOTÓN CERRAR CAJA (De la función 4)
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: (_closing || (totalRecaudado == 0 && pendiente == 0)) ? null : _closeRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _closing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Icon(Icons.lock_outline),
                label: Text('CERRAR CAJA DEL DÍA', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _subCard(String title, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('\$${CurrencyUtils.formatMoney(amount)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: zNavy),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : zNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? zBlue : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? zBlue : Colors.grey.shade300),
      ),
      child: Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : (isDark ? Colors.white : zNavy), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}