import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RetailerStoreLocationPickerScreen extends StatefulWidget {
  const RetailerStoreLocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<RetailerStoreLocationPickerScreen> createState() =>
      _RetailerStoreLocationPickerScreenState();
}

class _RetailerStoreLocationPickerScreenState
    extends State<RetailerStoreLocationPickerScreen>  with WidgetsBindingObserver {
  static const _bangaloreLocation = LatLng(12.9716, 77.5946);
  static const _nominatimEndpoint =
      'https://nominatim.openstreetmap.org/search';

  late final MapController _mapController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final http.Client _httpClient;

  late LatLng _selectedLocation;

  String _locationName = 'Bangalore';

  bool _isResolvingLocation = false;
  bool _isDetectingDeviceLocation = false;
  bool _isSearching = false;

  String? _searchMessage;
  bool _searchMessageIsError = false;

  List<_LocationSearchResult> _searchResults = [];

  final Map<String, List<_LocationSearchResult>> _searchCache =
      <String, List<_LocationSearchResult>>{};

  int _searchRequestId = 0;
  DateTime? _lastNominatimRequestAt;

  bool _locationSettingsOpened = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _mapController = MapController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _httpClient = http.Client();

    _selectedLocation = widget.initialLocation ?? _bangaloreLocation;

    if (widget.initialLocation != null) {
      _resolveLocationName(_selectedLocation);
    } else {
      _detectDeviceLocation();
    }
  }

  @override

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !_locationSettingsOpened ||
        !mounted) {
      return;
    }

    _locationSettingsOpened = false;

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _isDetectingDeviceLocation) {
        return;
      }

      _resumePreciseLocationDetection();
    });
  }

  Future<void> _resumePreciseLocationDetection() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!mounted) {
      return;
    }

    if (serviceEnabled) {
      await _detectDeviceLocation();
    } else {
      setState(() {
        _isResolvingLocation = false;
        _isDetectingDeviceLocation = false;
        _locationName = 'Location services are still turned off.';
      });
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _httpClient.close();
    super.dispose();
  }

  Future<void> _detectDeviceLocation() async {
    if (!mounted || _isDetectingDeviceLocation) {
      return;
    }

    setState(() {
      _isDetectingDeviceLocation = true;
      _isResolvingLocation = true;
      _locationName = 'Detecting your location…';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _finishLocationDetection(
          _bangaloreLocation,
          'Bangalore',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _finishLocationDetection(
          _bangaloreLocation,
          'Bangalore',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLocation = location;
        _isDetectingDeviceLocation = false;
        _isResolvingLocation = true;
        _locationName = 'Finding location…';
      });

      _mapController.move(
        location,
        16.0,
      );

      await _resolveLocationName(location);
    } catch (error) {
      debugPrint(
        'AUPNIX_RETAILER_STORE_LOCATION_DETECTION_ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      _finishLocationDetection(
        _bangaloreLocation,
        'Bangalore',
      );
    }
  }

  void _finishLocationDetection(
    LatLng location,
    String locationName,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = location;
      _locationName = locationName;
      _isDetectingDeviceLocation = false;
      _isResolvingLocation = false;
    });
  }

  Future<void> _resolveLocationName(LatLng location) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final geocoding = Geocoding();

      final placemarks = await geocoding
          .placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          )
          .timeout(
            const Duration(seconds: 6),
          );

      if (!mounted) {
        return;
      }

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = <String>[
          if ((place.name ?? '').trim().isNotEmpty)
            place.name!.trim(),
          if ((place.subLocality ?? '').trim().isNotEmpty)
            place.subLocality!.trim(),
          if ((place.locality ?? '').trim().isNotEmpty)
            place.locality!.trim(),
          if ((place.administrativeArea ?? '').trim().isNotEmpty &&
              (place.locality ?? '').trim() !=
                  (place.administrativeArea ?? '').trim())
            place.administrativeArea!.trim(),
        ];

        setState(() {
          _locationName = parts.isEmpty
              ? 'Selected store location'
              : parts.join(', ');
          _isResolvingLocation = false;
          _isDetectingDeviceLocation = false;
        });
      } else {
        setState(() {
          _locationName = 'Selected store location';
          _isResolvingLocation = false;
          _isDetectingDeviceLocation = false;
        });
      }
    } catch (error) {
      debugPrint(
        'AUPNIX_RETAILER_STORE_LOCATION_GEOCODING_ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locationName = 'Selected store location';
        _isResolvingLocation = false;
        _isDetectingDeviceLocation = false;
      });
    }
  }

  void _movePin(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationName = 'Finding location…';
      _isResolvingLocation = true;
      _isDetectingDeviceLocation = false;
      _searchResults = [];
      _searchMessage = null;
    });

    _resolveLocationName(location);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty || _isSearching) {
      return;
    }

    _searchFocusNode.unfocus();

    final normalizedQuery = query.toLowerCase();

    final cachedResults = _searchCache[normalizedQuery];

    if (cachedResults != null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = List<_LocationSearchResult>.from(cachedResults);
        _searchMessage = cachedResults.isEmpty
            ? 'No matching locations found.'
            : null;
        _searchMessageIsError = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;

    setState(() {
      _isSearching = true;
      _searchResults = [];
      _searchMessage = null;
      _searchMessageIsError = false;
    });

    try {
      await _respectNominatimRateLimit();

      final uri = Uri.parse(_nominatimEndpoint).replace(
        queryParameters: <String, String>{
          'q': query,
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'in',
          'accept-language': 'en',
        },
      );

      final response = await _httpClient
          .get(
            uri,
            headers: const <String, String>{
              'User-Agent': 'AUPNIX/1.0 (store location picker)',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Nominatim returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! List) {
        throw const FormatException(
          'Unexpected Nominatim response.',
        );
      }

      final results = decoded
          .whereType<Map>()
          .map(_LocationSearchResult.fromJson)
          .whereType<_LocationSearchResult>()
          .toList();

      _searchCache[normalizedQuery] =
          List<_LocationSearchResult>.from(results);

      setState(() {
        _isSearching = false;
        _searchResults = results;
        _searchMessage =
            results.isEmpty ? 'No matching locations found.' : null;
        _searchMessageIsError = false;
      });
    } on TimeoutException {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchMessage =
            'Search is taking too long. Please try again.';
        _searchMessageIsError = true;
      });
    } catch (error) {
      debugPrint(
        'AUPNIX_RETAILER_STORE_LOCATION_SEARCH_ERROR: $error',
      );

      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchMessage =
            'Could not search right now. Check your connection and try again.';
        _searchMessageIsError = true;
      });
    }
  }

  Future<void> _respectNominatimRateLimit() async {
    final lastRequest = _lastNominatimRequestAt;
    final now = DateTime.now();

    if (lastRequest != null) {
      final elapsed = now.difference(lastRequest);

      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(
          const Duration(seconds: 1) - elapsed,
        );
      }
    }

    _lastNominatimRequestAt = DateTime.now();
  }

  void _selectSearchResult(_LocationSearchResult result) {
    final location = LatLng(
      result.latitude,
      result.longitude,
    );

    _searchFocusNode.unfocus();

    setState(() {
      _selectedLocation = location;
      _locationName = result.displayName;
      _isResolvingLocation = false;
      _isDetectingDeviceLocation = false;
      _isSearching = false;
      _searchResults = [];
      _searchMessage = null;
      _searchController.text = result.shortName;
    });

    _mapController.move(
      location,
      16.0,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _searchMessage = null;
      _searchMessageIsError = false;
    });

    _searchFocusNode.requestFocus();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      currentZoom - 1,
    );
  }

  Future<void> _centerOnSelectedLocation() async {
    if (!mounted || _isDetectingDeviceLocation) {
      return;
    }

    setState(() {
      _isDetectingDeviceLocation = true;
      _isResolvingLocation = true;
      _locationName = 'Detecting your location…';
    });

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationName = 'Please enable location services…';
          });
        }

        _locationSettingsOpened = true;
        await Geolocator.openLocationSettings();

        if (!mounted) {
          return;
        }

        setState(() {
          _locationName = 'Checking location services…';
        });

        // Give Android a moment to propagate the changed system setting
        // before checking it again.
        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          if (mounted) {
            setState(() {
              _isDetectingDeviceLocation = false;
              _isResolvingLocation = false;
              _locationName = 'Location services are still turned off.';
            });
          }
          return;
        }
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isDetectingDeviceLocation = false;
            _isResolvingLocation = false;
            _locationName = 'Location permission is disabled.';
          });
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isDetectingDeviceLocation = false;
            _isResolvingLocation = false;
            _locationName = 'Location permission was not granted.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationName = 'Finding your precise location…';
        });
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLocation = location;
        _isDetectingDeviceLocation = false;
        _isResolvingLocation = true;
        _locationName = 'Finding location…';
      });

      _mapController.move(
        location,
        16.0,
      );

      await _resolveLocationName(location);
    } catch (error) {
      debugPrint(
        'AUPNIX_RETAILER_PRECISE_LOCATION_ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isDetectingDeviceLocation = false;
        _isResolvingLocation = false;
        _locationName = 'Unable to determine your location.';
      });
    }
  }
  void _confirmLocation() {
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom:
                  widget.initialLocation == null ? 13.0 : 16.0,
              minZoom: 3.0,
              maxZoom: 19.0,
              onTap: (_, point) => _movePin(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aupnix_new',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 58,
                    height: 68,
                    alignment: Alignment.topCenter,
                    child: const Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.store_rounded,
                                size: 28,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 32,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 28,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  0,
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x44000000),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () =>
                            Navigator.of(context).pop(),
                        tooltip: 'Back',
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0x44000000),
                        borderRadius: BorderRadius.circular(28),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 21,
                                color: Color(0xFF111111),
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Set your store location',
                                  style: TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 92,
            left: 16,
            right: 16,
            child: _buildSearchPanel(),
          ),

          Positioned(
            right: 16,
            bottom: 178,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: 14),
                _MapControlButton(
                  icon: Icons.my_location_outlined,
                  tooltip: 'Center on selected location',
                  onPressed: _centerOnSelectedLocation,
                ),
              ],
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                elevation: 8,
                shadowColor: const Color(0x55000000),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Store location',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Color(0xFF555555),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _locationName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (_isResolvingLocation)
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 8,
                                top: 1,
                              ),
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1C9F95),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF111111),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Confirm Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    final hasResults = _searchResults.isNotEmpty;
    final hasMessage = _searchMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          elevation: 5,
          shadowColor: const Color(0x44000000),
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: Icon(
                    Icons.search_rounded,
                    size: 24,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
          controller: _searchController,
          cursorColor: Colors.black,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchLocation(),
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search address or place',
                      hintStyle: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty &&
                    !_isSearching)
                  IconButton(
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 21,
                      color: Color(0xFF666666),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    onPressed:
                        _isSearching ? null : _searchLocation,
                    tooltip: 'Search',
                    icon: _isSearching
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Color(0xFF1C9F95),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: Color(0xFF111111),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasResults) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            elevation: 5,
            shadowColor: const Color(0x44000000),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 54,
                color: Color(0xFFE8E8E8),
              ),
              itemBuilder: (context, index) {
                final result = _searchResults[index];

                return InkWell(
                  onTap: () => _selectSearchResult(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 2,
                            top: 2,
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 22,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.shortName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF111111),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                result.displayName,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else if (hasMessage) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            elevation: 5,
            shadowColor: const Color(0x44000000),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    _searchMessageIsError
                        ? Icons.wifi_off_rounded
                        : Icons.location_searching_rounded,
                    size: 20,
                    color: _searchMessageIsError
                        ? const Color(0xFF666666)
                        : const Color(0xFF555555),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _searchMessage!,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationSearchResult {
  const _LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.shortName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final String shortName;

  static _LocationSearchResult? fromJson(Map result) {
    final latitude = double.tryParse(
      result['lat']?.toString() ?? '',
    );
    final longitude = double.tryParse(
      result['lon']?.toString() ?? '',
    );
    final displayName =
        result['display_name']?.toString().trim() ?? '';

    if (latitude == null ||
        longitude == null ||
        displayName.isEmpty) {
      return null;
    }

    final address =
        result['address'] is Map
            ? result['address'] as Map
            : const <String, dynamic>{};

    final shortNameCandidates = <String>[
      address['amenity']?.toString() ?? '',
      address['shop']?.toString() ?? '',
      address['building']?.toString() ?? '',
      address['road']?.toString() ?? '',
      address['suburb']?.toString() ?? '',
      address['city']?.toString() ?? '',
    ].map((value) => value.trim()).where(
          (value) => value.isNotEmpty,
        );

    final shortName = shortNameCandidates.isNotEmpty
        ? shortNameCandidates.first
        : displayName.split(',').first.trim();

    return _LocationSearchResult(
      latitude: latitude,
      longitude: longitude,
      displayName: displayName,
      shortName: shortName,
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x44000000),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: const Color(0xFF222222),
          size: 22,
        ),
      ),
    );
  }
}








