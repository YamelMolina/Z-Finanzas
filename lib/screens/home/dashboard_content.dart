import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/report_service.dart';
import '../../core/utils/currency_formatter.dart';

class DashboardContent extends StatefulWidget {
  final String userName;
  const DashboardContent({super.key, required this.userName});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _reportService.getDashboardStats();
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : zNavy;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SALUDO
          Text('Buenas noches 👋', style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade400 : zMuted)),
          const SizedBox(height: 4),
          Text('Tu cartera hoy', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),

          // TARJETA AZUL PRINCIPAL
          Container(
            width: double.infinity,
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
                    Text('CAPITAL EN CIRCULACIÓN', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.show_chart, color: Colors.white, size: 16),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text('\$${CurrencyUtils.formatMoney(_stats!['dinero_por_cobrar'])}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 4),
                    Text('Recuperado \$${CurrencyUtils.formatMoney(_stats!['total_cobrado'])}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                // SUB TARJETAS
                Row(
                  children: [
                    _subCard('PENDIENTE', _stats!['capital_prestado']),
                    const SizedBox(width: 10),
                    _subCard('HOY', 1050000), // Dato de ejemplo, lo conectas a tu lógica
                    const SizedBox(width: 10),
                    _subCard('CAJA', 6900000), // Dato de ejemplo
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // RESUMEN DEL DÍA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, color: zBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Resumen del Día', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                _resumenItem('💰', 'Hoy tienes 2 cobro(s) pendiente(s).', Colors.transparent, textColor),
                _resumenItem('📊', 'Recuperarás aproximadamente \$ 14.000 si completas todos los cobros.', Colors.transparent, textColor),
                _resumenItem('⚠️', 'Existen 16 cliente(s) con pagos vencidos.', Colors.red, textColor),
                _resumenItem('🎉', '9 préstamo(s) terminan esta semana.', Colors.transparent, textColor),
                _resumenItem('✅', 'Ya registraste 30 pago(s) hoy.', Colors.transparent, textColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PRÓXIMOS COBROS (Título)
          Text('Próximos Cobros', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              _tabChip('Hoy vencen', true),
              _tabChip('Mañana', false),
              _tabChip('Semana', false),
            ],
          )
        ],
      ),
    );
  }

  Widget _subCard(String title, dynamic amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('\$${CurrencyUtils.formatMoney(amount)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String emoji, String text, Color textColor, Color defaultColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: textColor == Colors.transparent ? defaultColor : textColor, fontWeight: textColor == Colors.red ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? zBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? zBlue : Colors.grey.shade300),
      ),
      child: Text(text, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}