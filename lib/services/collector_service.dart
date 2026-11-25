import 'package:supabase_flutter/supabase_flutter.dart';

class CollectorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    
    final res = await _supabase.from('company_members').select('company_id').eq('user_id', user.id).limit(1).maybeSingle();
    if (res == null) throw Exception('Usuario sin empresa.');
    return res['company_id'] as String;
  }

  Future<List<Map<String, dynamic>>> getCollectors() async {
    final companyId = await _getCompanyId();
    
    final response = await _supabase
        .from('collectors')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createCollector({
    required String fullName,
    required String phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');
    
    final companyId = await _getCompanyId();

    await _supabase.from('collectors').insert({
      'company_id': companyId,
      'created_by': user.id,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'active': true,
    });
  }

  Future<void> setCollectorActive({
    required String id,
    required bool active,
  }) async {
    final companyId = await _getCompanyId();

    await _supabase
        .from('collectors')
        .update({'active': active})
        .eq('id', id)
        .eq('company_id', companyId);
  }
}