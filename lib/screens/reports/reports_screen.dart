import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../main.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _service = ReportService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  Map<String, List<double>>? _chartData;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getDashboardStats();
      final charts = await _service.getWeeklyChartData();
      if (!mounted) return;
      setState(() { _stats = data; _chartData = charts; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : zNavy;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _loadStats, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen del Negocio', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 24),
                          _buildGrid(isDark),
                          const SizedBox(height: 32),
                          Text('Flujo de los últimos 7 días', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 16),
                          _buildLineChart(isDark),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    if (_chartData == null) return const SizedBox();
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = ['Hace 6d', 'Hace 5d', 'Hace 4d', 'Hace 3d', 'Antier', 'Ayer', 'Hoy'];
                  return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), _chartData!['income']![i])),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
            ),
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), _chartData!['loans']![i])),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final stats = [
      {'title': 'Total Clientes', 'value': '${_stats!['total_clients']}', 'icon': Icons.people, 'color': Colors.blue},
      {'title': 'Préstamos Activos', 'value': '${_stats!['prestamos_activos']}', 'icon': Icons.account_balance, 'color': Colors.orange},
      {'title': 'Capital Prestado', 'value': '\$${CurrencyUtils.formatMoney(_stats!['capital_prestado'])}', 'icon': Icons.money_off, 'color': Colors.red},
      {'title': 'Total Cobrado', 'value': '\$${CurrencyUtils.formatMoney(_stats!['total_cobrado'])}', 'icon': Icons.payments, 'color': Colors.green},
      {'title': 'Dinero por Cobrar', 'value': '\$${CurrencyUtils.formatMoney(_stats!['dinero_por_cobrar'])}', 'icon': Icons.hourglass_empty, 'color': Colors.purple},
      {'title': 'Ganancia Estimada', 'value': '\$${CurrencyUtils.formatMoney(_stats!['ganancia_estimada'])}', 'icon': Icons.trending_up, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemBuilder: (context, index) {
        final s = stats[index];
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s['icon'] as IconData, color: color, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['title'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(s['value'] as String, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}