import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessService {
  BusinessService._();

  static final BusinessService instance = BusinessService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Create a business and assign the authenticated user as its initial owner.
  Future<String> createBusinessWithInitialOwner() async {
    final businessId = await _supabase.rpc(
      'create_business_with_initial_owner',
    );

    if (businessId is! String || businessId.trim().isEmpty) {
      throw StateError(
        'Business creation did not return a valid business ID.',
      );
    }

    return businessId;
  }
}
