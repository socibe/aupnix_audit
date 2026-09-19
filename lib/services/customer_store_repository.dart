import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_store_data.dart';

class CustomerStoreRepository {
  CustomerStoreRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<CustomerStoreData?> getByBusinessLocationId(
    String businessLocationId,
  ) async {
    final location = await _client
        .from('business_locations')
        .select(
          'id, business_id, address_line_1, address_line_2, locality, city, '
          'state, country_code, postal_code, latitude, longitude, status, is_primary',
        )
        .eq('id', businessLocationId)
        .maybeSingle();

    if (location == null) {
      return null;
    }

    final businessId = location['business_id'];
    if (businessId is! String) {
      return null;
    }

    final business = await _client
        .from('businesses')
        .select('id, status')
        .eq('id', businessId)
        .maybeSingle();

    if (business == null) {
      return null;
    }

    final profile = await _client
        .from('business_profiles')
        .select(
          'business_id, display_name, description, contact_phone, contact_email',
        )
        .eq('business_id', businessId)
        .maybeSingle();

    if (profile == null) {
      return null;
    }

    final latitude = location['latitude'];
    final longitude = location['longitude'];

    return CustomerStoreData(
      businessId: business['id'] as String,
      businessStatus: business['status'] as String,
      displayName: profile['display_name'] as String,
      description: profile['description'] as String?,
      contactPhone: profile['contact_phone'] as String?,
      contactEmail: profile['contact_email'] as String?,
      locationId: location['id'] as String,
      locationStatus: location['status'] as String,
      addressLine1: location['address_line_1'] as String,
      addressLine2: location['address_line_2'] as String?,
      locality: location['locality'] as String?,
      city: location['city'] as String,
      state: location['state'] as String,
      countryCode: location['country_code'] as String,
      postalCode: location['postal_code'] as String?,
      latitude: latitude is num ? latitude.toDouble() : null,
      longitude: longitude is num ? longitude.toDouble() : null,
      isPrimary: location['is_primary'] as bool,
    );
  }
}
