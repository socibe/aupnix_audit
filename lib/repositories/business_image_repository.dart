import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_image.dart';

class BusinessImageRepository {
  BusinessImageRepository._();

  static final BusinessImageRepository instance =
      BusinessImageRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<BusinessImage?> getBusinessImage({
    required String businessId,
    required String imageRole,
  }) async {
    final row = await _supabase
        .from('business_images')
        .select()
        .eq('business_id', businessId)
        .eq('image_role', imageRole)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return BusinessImage.fromMap(row);
  }

  Future<BusinessImage> upsertBusinessImage({
    required String businessId,
    required String storageKey,
    required String imageRole,
    String? altText,
    int displayOrder = 0,
  }) async {
    if (imageRole != BusinessImage.profileRole &&
        imageRole != BusinessImage.bannerRole) {
      throw ArgumentError.value(
        imageRole,
        'imageRole',
        'Must be profile or banner.',
      );
    }

    final existing = await getBusinessImage(
      businessId: businessId,
      imageRole: imageRole,
    );

    final values = <String, dynamic>{
      'business_id': businessId,
      'storage_key': storageKey,
      'image_role': imageRole,
      'alt_text': altText,
      'display_order': displayOrder,
    };

    if (existing != null) {
      values['id'] = existing.id;
    }

    final rows = await _supabase
        .from('business_images')
        .upsert(
          values,
          onConflict: 'business_id,image_role',
        )
        .select()
        .single();

    return BusinessImage.fromMap(rows);
  }

  Future<void> deleteBusinessImage({
    required String businessId,
    required String imageRole,
  }) async {
    await _supabase
        .from('business_images')
        .delete()
        .eq('business_id', businessId)
        .eq('image_role', imageRole);
  }
}

