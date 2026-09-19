import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessProfileRepository {
  BusinessProfileRepository._();

  static final BusinessProfileRepository instance =
      BusinessProfileRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>?> getBusinessProfile(
    String businessId,
  ) async {
    return _supabase
        .from('business_profiles')
        .select('business_id, display_name, description, contact_phone, contact_email')
        .eq('business_id', businessId)
        .maybeSingle();
  }

  Future<void> saveBusinessInformation({
    required String businessId,
    required String displayName,
    String? description,
  }) async {
    final existing = await getBusinessProfile(businessId);

    if (existing != null) {
      await _supabase
          .from('business_profiles')
          .update({
            'display_name': displayName,
            'description': description,
          })
          .eq('business_id', businessId);

      return;
    }

    await _supabase.from('business_profiles').insert({
      'business_id': businessId,
      'display_name': displayName,
      'description': description,
    });
  }
  Future<void> updateContactPhone({
    required String businessId,
    required String contactPhone,
  }) async {
    await _supabase
        .from('business_profiles')
        .update({
          'contact_phone': contactPhone,
        })
        .eq('business_id', businessId);
  }

  Future<void> upsertBusinessProfile({
    required String businessId,
    required String displayName,
    String? description,
    String? contactPhone,
  }) async {
    await _supabase.from('business_profiles').upsert(
      {
        'business_id': businessId,
        'display_name': displayName,
        'description': description,
        'contact_phone': contactPhone,
      },
      onConflict: 'business_id',
    );
  }
}
