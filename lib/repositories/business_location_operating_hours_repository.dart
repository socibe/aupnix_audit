import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessLocationOperatingHoursRepository {
  BusinessLocationOperatingHoursRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getForLocation(
    String businessLocationId,
  ) async {
    final rows = await _client
        .from('business_location_operating_hours')
        .select(
          'id, business_location_id, day_of_week, is_closed, '
          'opening_time, closing_time',
        )
        .eq('business_location_id', businessLocationId)
        .order('day_of_week');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> replaceForLocation({
    required String businessLocationId,
    required Map<int, TimeOfDay?> openingTimes,
    required Map<int, TimeOfDay?> closingTimes,
    required Set<int> closedDays,
  }) async {
    for (var dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      if (closedDays.contains(dayOfWeek)) {
        await _client
            .from('business_location_operating_hours')
            .upsert(
              {
                'business_location_id': businessLocationId,
                'day_of_week': dayOfWeek,
                'is_closed': true,
                'opening_time': null,
                'closing_time': null,
              },
              onConflict: 'business_location_id,day_of_week',
            );
        continue;
      }

      final opening = openingTimes[dayOfWeek];
      final closing = closingTimes[dayOfWeek];

      if (opening == null || closing == null) {
        throw ArgumentError(
          'Opening and closing times are required for day $dayOfWeek.',
        );
      }

      await _client
          .from('business_location_operating_hours')
          .upsert(
            {
              'business_location_id': businessLocationId,
              'day_of_week': dayOfWeek,
              'is_closed': false,
              'opening_time': _toPostgresTime(opening),
              'closing_time': _toPostgresTime(closing),
            },
            onConflict: 'business_location_id,day_of_week',
          );
    }
  }

  String _toPostgresTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }
}
