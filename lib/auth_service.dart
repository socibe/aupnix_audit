import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Create a new AUPNIX account.
  ///
  /// The mobile number is stored as user metadata.
  /// It is NOT used for phone verification.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'mobile_number': mobileNumber,
      },
      emailRedirectTo: 'aupnix://login-callback',
    );

    return response;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Send a password-reset email.
  Future<void> resetPassword({
    required String email,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'aupnix://login-callback',
    );
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'aupnix://login-callback',
      queryParams: const {
        'prompt': 'select_account',
      },
    );
  }

  /// Save the authenticated user's onboarding role.
  Future<void> saveOnboardingRole({
    required String role,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    await _supabase.from('user_onboarding_roles').upsert(
      {
        'user_id': user.id,
        'role': role,
      },
      onConflict: 'user_id',
    );
  }

  /// Retrieve the authenticated user's saved onboarding role.
  Future<String?> getOnboardingRole() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    final row = await _supabase.from('user_onboarding_roles').select('role').eq('user_id', user.id).maybeSingle();
    return row?['role'] as String?;
  }

  /// Update the authenticated user's password.
  Future<void> updatePassword({
    required String password,
  }) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Current Supabase session.
  Session? get currentSession => _supabase.auth.currentSession;

  /// Current Supabase user.
  User? get currentUser => _supabase.auth.currentUser;
}


