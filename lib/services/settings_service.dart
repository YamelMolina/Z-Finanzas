import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getCompanyInfo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión.');

    final res = await _supabase
        .from('company_members')
        .select('company_id, companies(name)')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (res == null) throw Exception('Usuario sin empresa.');
    
    return {
      'id': res['company_id'],
      'name': res['companies']['name'],
    };
  }

  Future<void> updateCompanyName(String companyId, String newName) async {
    await _supabase.from('companies').update({'name': newName}).eq('id', companyId);
  }
}