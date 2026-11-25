import 'package:supabase_flutter/supabase_flutter.dart';

class CashService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    final res = await _supabase.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    if (res == null) throw Exception('Usuario sin empresa.');
    return res['company_id'] as String;
  }

  Future<Map<String, dynamic>> getDailySummary() async {
    final companyId = await _getCompanyId();
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

    final loansResponse = await _supabase
        .from('loans')
        .select('*, clients(full_name)')
        .eq('company_id', companyId)
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay)
        .order('created_at', ascending: false);

    final paymentsResponse = await _supabase
        .from('payments')
        .select('*, clients(full_name)')
        .eq('company_id', companyId)
        .gte('payment_date', startOfDay)
        .lte('payment_date', endOfDay)
        .order('payment_date', ascending: false);

    final loans = List<Map<String, dynamic>>.from(loansResponse);
    final payments = List<Map<String, dynamic>>.from(paymentsResponse);

    double totalLoans = 0;
    for (var l in loans) { totalLoans += (l['amount'] as num).toDouble(); }

    double totalPayments = 0;
    for (var p in payments) { totalPayments += (p['amount'] as num).toDouble(); }

    return {
      'total_loans': totalLoans,
      'total_payments': totalPayments,
      'balance': totalPayments - totalLoans,
      'loans': loans,
      'payments': payments,
    };
  }

  // NUEVO: Cierre de Caja
  Future<void> closeRegister({
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    final companyId = await _getCompanyId();

    await _supabase.from('cash_closings').insert({
      'company_id': companyId,
      'closed_by': user.id,
      'total_income': totalIncome,
      'total_expenses': totalExpenses,
      'balance': balance,
    });
  }
}