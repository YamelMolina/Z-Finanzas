import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    final res = await _supabase.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    if (res == null) throw Exception('Usuario sin empresa.');
    return res['company_id'] as String;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final companyId = await _getCompanyId();
    
    final responses = await Future.wait([
      _supabase.from('clients').select('id').eq('company_id', companyId),
      _supabase.from('loans').select('amount, total_to_pay, status').eq('company_id', companyId),
      _supabase.from('payments').select('amount').eq('company_id', companyId),
    ]);

    final clients = responses[0];
    final loans = responses[1];
    final payments = responses[2];

    int totalClients = clients.length;
    double capitalPrestado = 0;
    double dineroPorCobrar = 0;
    int prestamosActivos = 0;

    for (var loan in loans) {
      capitalPrestado += (loan['amount'] as num).toDouble();
      if (loan['status'] == 'activo') {
        prestamosActivos++;
        dineroPorCobrar += (loan['total_to_pay'] as num).toDouble();
      }
    }

    double totalCobrado = 0;
    for (var payment in payments) {
      totalCobrado += (payment['amount'] as num).toDouble();
    }

    double gananciaEstimada = dineroPorCobrar - capitalPrestado;

    return {
      'total_clients': totalClients,
      'prestamos_activos': prestamosActivos,
      'capital_prestado': capitalPrestado,
      'total_cobrado': totalCobrado,
      'dinero_por_cobrar': dineroPorCobrar,
      'ganancia_estimada': gananciaEstimada,
    };
  }

  // NUEVO: Obtener datos de los últimos 7 días para las gráficas
  Future<Map<String, List<double>>> getWeeklyChartData() async {
    final companyId = await _getCompanyId();
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));

    final payments = await _supabase
        .from('payments')
        .select('amount, payment_date')
        .eq('company_id', companyId)
        .gte('payment_date', startDate.toUtc().toIso8601String());

    final loans = await _supabase
        .from('loans')
        .select('amount, created_at')
        .eq('company_id', companyId)
        .gte('created_at', startDate.toUtc().toIso8601String());

    List<double> dailyIncome = List.filled(7, 0);
    List<double> dailyLoans = List.filled(7, 0);

    for (var p in payments) {
      final date = DateTime.parse(p['payment_date']).toLocal();
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        dailyIncome[6 - diff] += (p['amount'] as num).toDouble();
      }
    }

    for (var l in loans) {
      final date = DateTime.parse(l['created_at']).toLocal();
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        dailyLoans[6 - diff] += (l['amount'] as num).toDouble();
      }
    }

    return {
      'income': dailyIncome,
      'loans': dailyLoans,
    };
  }
}