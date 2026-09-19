import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  final Geocoding _geocoding = Geocoding();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<SavedUserLocation?> getSavedLocation() async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return null;
    }

    final row = await _supabase
        .from('user_locations')
        .select('latitude, longitude')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final latitude = (row['latitude'] as num?)?.toDouble();
    final longitude = (row['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      return null;
    }

    return SavedUserLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
  Future<void> saveCurrentLocation() async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      throw const LocationServiceException(
        'No authenticated user is available.',
      );
    }

    var serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw const LocationServiceException(
          'Location services are still disabled.',
          code: LocationServiceErrorCode.serviceDisabled,
        );
      }
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission was denied. Please allow access to continue.',
        code: LocationServiceErrorCode.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is off. Please turn it on in your device settings.',
        code: LocationServiceErrorCode.permissionDeniedForever,
      );
    }

    late final Position position;

    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      throw const LocationServiceException(
        'Unable to determine the current location.',
        code: LocationServiceErrorCode.locationFailed,
      );
    }

    late final List<Placemark> placemarks;

    try {
      placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      throw const LocationServiceException(
        'Unable to determine an address for the current location.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    if (placemarks.isEmpty) {
      throw const LocationServiceException(
        'Unable to determine an address for the current location.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    final placemark = placemarks.first;

    final addressLine1 = _firstNonEmpty([
      placemark.street,
      placemark.name,
    ]);

    final city = _firstNonEmpty([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.subLocality,
    ]);

    final state = _firstNonEmpty([
      placemark.administrativeArea,
      placemark.subAdministrativeArea,
    ]);

    if (addressLine1 == null || city == null || state == null) {
      throw const LocationServiceException(
        'The current location did not provide a complete address.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    final addressLine2 = _joinNonEmpty([
      placemark.subLocality,
      placemark.subThoroughfare,
    ]);

    try {
      await _supabase.from('user_locations').upsert(
        {
          'user_id': user.id,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address_line_1': addressLine1,
          'address_line_2': addressLine2,
          'city': city,
          'state': state,
          'postal_code': _firstNonEmpty([
            placemark.postalCode,
          ]),
        },
        onConflict: 'user_id',
      );
    } catch (_) {
      throw const LocationServiceException(
        'Unable to save the current location.',
        code: LocationServiceErrorCode.saveFailed,
      );
    }
  }

  Future<void> saveManualLocation({
    required String address,
  }) async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      throw const LocationServiceException(
        'No authenticated user is available.',
      );
    }

    final normalizedAddress = address.trim();

    if (normalizedAddress.isEmpty) {
      throw const LocationServiceException(
        'Please enter a location.',
        code: LocationServiceErrorCode.emptyAddress,
      );
    }

    late final List<Location> locations;

    try {
      locations = await _geocoding.locationFromAddress(
        normalizedAddress,
      );
    } catch (_) {
      throw const LocationServiceException(
        'We could not find that location. Please check the address and try again.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    if (locations.isEmpty) {
      throw const LocationServiceException(
        'We could not find that location. Please check the address and try again.',
        code: LocationServiceErrorCode.noGeocodingResult,
      );
    }

    final location = _selectManualLocation(locations);

    late final List<Placemark> placemarks;

    try {
      placemarks = await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (_) {
      throw const LocationServiceException(
        'We could not determine the address for that location.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    if (placemarks.isEmpty) {
      throw const LocationServiceException(
        'We could not determine the address for that location.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    final placemark = placemarks.first;

    final addressLine1 = _firstNonEmpty([
      placemark.street,
      placemark.name,
      normalizedAddress,
    ]);

    final city = _firstNonEmpty([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.subLocality,
    ]);

    final state = _firstNonEmpty([
      placemark.administrativeArea,
      placemark.subAdministrativeArea,
    ]);

    if (addressLine1 == null || city == null || state == null) {
      throw const LocationServiceException(
        'The selected location did not provide a complete address.',
        code: LocationServiceErrorCode.geocodingFailed,
      );
    }

    final addressLine2 = _joinNonEmpty([
      placemark.subLocality,
      placemark.subThoroughfare,
    ]);

    try {
      await _supabase.from('user_locations').upsert(
        {
          'user_id': user.id,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address_line_1': addressLine1,
          'address_line_2': addressLine2,
          'city': city,
          'state': state,
          'postal_code': _firstNonEmpty([
            placemark.postalCode,
          ]),
        },
        onConflict: 'user_id',
      );
    } catch (_) {
      throw const LocationServiceException(
        'Unable to save the selected location. Please try again.',
        code: LocationServiceErrorCode.saveFailed,
      );
    }
  }

  Location _selectManualLocation(List<Location> locations) {
    if (locations.length == 1) {
      return locations.first;
    }

    return locations.first;
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();

      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  String? _joinNonEmpty(Iterable<String?> values) {
    final parts = values
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }
}

enum LocationServiceErrorCode {
  emptyAddress,
  noGeocodingResult,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  locationFailed,
  geocodingFailed,
  saveFailed,
}

class LocationServiceException implements Exception {
  const LocationServiceException(
    this.message, {
    this.code,
  });

  final String message;
  final LocationServiceErrorCode? code;

  @override
  String toString() => message;
}

class SavedUserLocation {
  const SavedUserLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
