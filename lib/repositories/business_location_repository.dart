import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessLocationRepository {
  BusinessLocationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getPrimaryLocation(
    String businessId,
  ) async {
    return _client
        .from('business_locations')
        .select(
          'id, business_id, address_line_1, address_line_2, locality, '
          'city, state, country_code, postal_code, latitude, longitude, '
          'status, is_primary',
        )
        .eq('business_id', businessId)
        .eq('is_primary', true)
        .eq('status', 'active')
        .maybeSingle();
  }

  Future<String> upsertPrimaryLocation({
    required String businessId,
    required String addressLine1,
    String? addressLine2,
    String? locality,
    required String city,
    required String state,
    required String postalCode,
    double? latitude,
    double? longitude,
  }) async {
    final existing = await getPrimaryLocation(businessId);

    final values = <String, dynamic>{
      'business_id': businessId,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'locality': locality,
      'city': city,
      'state': state,
      'country_code': 'IN',
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': true,
      'status': 'active',
    };

    if (existing != null) {
      final locationId = existing['id'];

      if (locationId is! String || locationId.trim().isEmpty) {
        throw StateError(
          'Primary business location has an invalid ID.',
        );
      }

      final row = await _client
          .from('business_locations')
          .update(values)
          .eq('id', locationId)
          .select('id')
          .single();

      final updatedId = row['id'];
      if (updatedId is! String || updatedId.trim().isEmpty) {
        throw StateError(
          'Business location update did not return a valid location ID.',
        );
      }

      return updatedId;
    }

    final row = await _client
        .from('business_locations')
        .insert(values)
        .select('id')
        .single();

    final createdId = row['id'];
    if (createdId is! String || createdId.trim().isEmpty) {
      throw StateError(
        'Business location creation did not return a valid location ID.',
      );
    }

    return createdId;
  }
}
