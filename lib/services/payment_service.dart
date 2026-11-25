import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    
    final res = await _supabase.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    if (res == null) throw Exception('Usuario sin empresa.');
    return res['company_id'] as String;
  }

  // Obtener historial de cobros
  Future<List<Map<String, dynamic>>> getPayments() async {
    final companyId = await _getCompanyId();
    
    final response = await _supabase
        .from('payments')
        .select('*, clients(full_name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  // Obtener préstamos activos para poder cobrarles
  Future<List<Map<String, dynamic>>> getActiveLoans() async {
    final companyId = await _getCompanyId();
    
    final response = await _supabase
        .from('loans')
        .select('*, clients(full_name)')
        .eq('company_id', companyId)
        .eq('status', 'activo')
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  // Registrar un nuevo cobro
  Future<void> createPayment({
    required String loanId,
    required String clientId,
    required double amount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    
    final companyId = await _getCompanyId();

    await _supabase.from('payments').insert({
      'company_id': companyId,
      'loan_id': loanId,
      'client_id': clientId,
      'created_by': user.id,
      'amount': amount,
    });
  }
}