import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
    );

    final user = response.user;

    if (user == null) {
      throw Exception(
        'No se pudo crear el usuario. Verifica tu correo o intenta nuevamente.',
      );
    }

    // La empresa se crea cuando Supabase confirma la sesión.
    if (response.session != null) {
      await _createProfileAndCompany(
        userId: user.id,
        name: name,
        companyName: companyName,
      );
    }
  }

  Future<void> completeRegistration({
    required String name,
    required String companyName,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Debes iniciar sesión primero.');
    }

    await _createProfileAndCompany(
      userId: user.id,
      name: name,
      companyName: companyName,
    );
  }

  Future<void> _createProfileAndCompany({
    required String userId,
    required String name,
    required String companyName,
  }) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'full_name': name.trim(),
    });

    await _supabase.rpc(
      'create_company',
      params: {'p_name': companyName.trim()},
    );
  }

  Future<void> login({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authChanges => _supabase.auth.onAuthStateChange;
}
