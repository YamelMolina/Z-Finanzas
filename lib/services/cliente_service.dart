import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la empresa del usuario autenticado.
  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final membership = await _supabase
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (membership == null) {
      throw Exception('El usuario no pertenece a ninguna empresa.');
    }

    return membership['company_id'] as String;
  }

  /// Consulta los clientes de la empresa.
  Future<List<Map<String, dynamic>>> getClients({
    bool includeInactive = false,
  }) async {
    final companyId = await _getCompanyId();

    var query = _supabase.from('clients').select().eq('company_id', companyId);

    if (!includeInactive) {
      query = query.eq('active', true);
    }

    final response = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Registra un cliente.
  Future<Map<String, dynamic>> createClient({
    required String fullName,
    String? documentNumber,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final companyId = await _getCompanyId();

    final response = await _supabase
        .from('clients')
        .insert({
          'company_id': companyId,
          'created_by': user.id,
          'full_name': fullName.trim(),
          'document_number': _clean(documentNumber),
          'phone': _clean(phone),
          'address': _clean(address),
          'notes': _clean(notes),
          'active': true,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Actualiza los datos de un cliente.
  Future<Map<String, dynamic>> updateClient({
    required String clientId,
    required String fullName,
    String? documentNumber,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final companyId = await _getCompanyId();

    final response = await _supabase
        .from('clients')
        .update({
          'full_name': fullName.trim(),
          'document_number': _clean(documentNumber),
          'phone': _clean(phone),
          'address': _clean(address),
          'notes': _clean(notes),
        })
        .eq('id', clientId)
        .eq('company_id', companyId)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Desactiva un cliente sin eliminar su historial.
  Future<void> deactivateClient(String clientId) async {
    final companyId = await _getCompanyId();

    await _supabase
        .from('clients')
        .update({'active': false})
        .eq('id', clientId)
        .eq('company_id', companyId);
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
