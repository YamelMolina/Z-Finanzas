import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay una sesión activa.');

    final membership = await _supabase
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (membership == null) {
      throw Exception('No se encontró una empresa asociada a este usuario.');
    }

    return membership['company_id'] as String;
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final companyId = await _getCompanyId();

    final response = await _supabase
        .from('clients')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createClient({
    required String fullName,
    required String documentNumber,
    required String phone,
    required String address,
    required String notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay una sesión activa.');

    final companyId = await _getCompanyId();

    await _supabase.from('clients').insert({
      'company_id': companyId,
      'created_by': user.id,
      'full_name': fullName.trim(),
      'document_number': documentNumber.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'active': true,
    });
  }

  Future<void> updateClient({
    required String id,
    required String fullName,
    required String documentNumber,
    required String phone,
    required String address,
    required String notes,
  }) async {
    final companyId = await _getCompanyId();

    await _supabase
        .from('clients')
        .update({
          'full_name': fullName.trim(),
          'document_number': documentNumber.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'notes': notes.trim(),
        })
        .eq('id', id)
        .eq('company_id', companyId);
  }

  Future<void> setClientActive({
    required String id,
    required bool active,
  }) async {
    final companyId = await _getCompanyId();

    await _supabase
        .from('clients')
        .update({'active': active})
        .eq('id', id)
        .eq('company_id', companyId);
  }
}