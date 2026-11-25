import 'package:supabase_flutter/supabase_flutter.dart';

class LoanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    final res = await _supabase.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    if (res == null) throw Exception('Usuario sin empresa.');
    return res['company_id'] as String;
  }

  Future<List<Map<String, dynamic>>> getLoans() async {
    final companyId = await _getCompanyId();
    
    // AGREGAMOS LA RELACIÓN CON COLLECTORS
    final response = await _supabase
        .from('loans')
        .select('*, clients(full_name, phone), collectors(full_name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createLoan({
    required String clientId,
    required double amount,
    required double interestRate,
    required double totalToPay,
    required int installments,
    required String frequency,
    String? collectorId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    final companyId = await _getCompanyId();

    await _supabase.from('loans').insert({
      'company_id': companyId,
      'client_id': clientId,
      'created_by': user.id,
      'amount': amount,
      'interest_rate': interestRate,
      'total_to_pay': totalToPay,
      'installments': installments,
      'frequency': frequency,
      'status': 'activo',
      'collector_id': collectorId, // <-- NUEVO CAMPO
    });
  }
}