import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import '../location_service.dart';
import '../screens/product_details_screen.dart';

class CustomerStoreAvailabilityService {
  CustomerStoreAvailabilityService._();

  static final CustomerStoreAvailabilityService instance =
      CustomerStoreAvailabilityService._();

  final Map<String, _ResolvedStoreLocation> _locationCache =
      <String, _ResolvedStoreLocation>{};

  static const List<_StoreDefinition> _knownStores = [
    _StoreDefinition(
      name: 'Croma - HSR Layout',
      address:
          'No 4/4, Ward No 174, BBMP, Hosur Sarjapur Road, HSR Layout Sector 7, Bengaluru, Karnataka 560102, India',
      priceMultiplier: 1.00,
    ),
    _StoreDefinition(
      name: 'Star Market',
      address:
          'VGR Essor, 17th Cross, 5th Main, HSR Layout 7th Sector, Bengaluru, Karnataka 560102, India',
      priceMultiplier: 0.96,
    ),
    _StoreDefinition(
      name: 'Reliance Smart',
      address:
          '403, 22nd Cross Road, Parangi Palaya, BDA Layout, HSR Layout, Bengaluru, Karnataka 560102, India',
      priceMultiplier: 1.03,
    ),
    _StoreDefinition(
      name: 'More Megastore',
      address:
          'BDA Site No. 435, 27th Main, Hosur Sarjapura Road Layout Sector-I, Agara, Bengaluru, Karnataka 560034, India',
      priceMultiplier: 0.94,
    ),
  ];

  Future<List<ProductStoreAvailability>> buildForProduct(
    ProductDetailsProduct product,
  ) async {
    final userLocation =
        await LocationService.instance.getSavedLocation();

    final existingByName = <String, ProductStoreAvailability>{
      for (final store in product.nearbyStores)
        _normalize(store.storeName): store,
    };

    final stores = <ProductStoreAvailability>[];

    for (final definition in _knownStores) {
      final existing = existingByName[_normalize(definition.name)];

      final basePrice = existing?.price ?? product.price;

      final location = await _resolveStoreLocation(definition);

      final distanceKm = userLocation == null || location == null
          ? null
          : Geolocator.distanceBetween(
                userLocation.latitude,
                userLocation.longitude,
                location.latitude,
                location.longitude,
              ) /
              1000;

      final availability = existing?.availability ?? 'Available';
      final isOpen = existing?.isOpen ?? true;

      if (availability.toLowerCase() == 'out of stock' || !isOpen) {
        continue;
      }

      stores.add(
        ProductStoreAvailability(
          storeName: definition.name,
          distance: _formatDistance(distanceKm),
          distanceKm: distanceKm,
          availability: availability,
          price: existing == null
              ? _adjustPrice(basePrice, definition.priceMultiplier)
              : existing.price,
          isOpen: isOpen,
          storeImage: existing?.storeImage,
          businessLocationId: null,
        ),
      );
    }

    for (final existing in product.nearbyStores) {
      final alreadyIncluded = stores.any(
        (store) =>
            _normalize(store.storeName) == _normalize(existing.storeName),
      );

      if (!alreadyIncluded) {
        stores.add(existing);
      }
    }

    stores.sort((a, b) {
      final aDistance = a.distanceKm;
      final bDistance = b.distanceKm;

      if (aDistance == null && bDistance == null) {
        return 0;
      }

      if (aDistance == null) {
        return 1;
      }

      if (bDistance == null) {
        return -1;
      }

      return aDistance.compareTo(bDistance);
    });

    return stores;
  }

  Future<ProductStoreAvailability?> nearestAvailableStoreForProduct(
    ProductDetailsProduct product,
  ) async {
    final stores = await buildForProduct(product);
    if (stores.isEmpty) {
      return null;
    }
    return stores.first;
  }  Future<_ResolvedStoreLocation?> _resolveStoreLocation(
    _StoreDefinition definition,
  ) async {
    final cacheKey = _normalize(definition.name);

    final cached = _locationCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final locations = await geocoding.Geocoding().locationFromAddress(definition.address);

      if (locations.isEmpty) {
        return null;
      }

      final location = _ResolvedStoreLocation(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
      );

      _locationCache[cacheKey] = location;

      return location;
    } catch (_) {
      return null;
    }
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) {
      return 'Distance unavailable';
    }

    if (distanceKm < 1) {
      final metres = (distanceKm * 1000).round();
      return '$metres m away';
    }

    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  double _adjustPrice(double value, double multiplier) {
    if (value <= 0) {
      return value;
    }

    return double.parse((value * multiplier).toStringAsFixed(2));
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _StoreDefinition {
  const _StoreDefinition({
    required this.name,
    required this.address,
    required this.priceMultiplier,
  });

  final String name;
  final String address;
  final double priceMultiplier;
}

class _ResolvedStoreLocation {
  const _ResolvedStoreLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}


