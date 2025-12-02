import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Google-powered location picker with Places Autocomplete and reverse geocoding.
///
/// API keys:
/// - Maps SDK: configured per platform (Android Manifest, iOS Info.plist, web/index.html script tag)
/// - REST calls (Places/Geocoding): read from `GMAPS_API_KEY` via dart-define.
///   Example: `flutter run -d chrome --dart-define=GMAPS_API_KEY=YOUR_KEY`.
class GoogleLocationPicker extends StatefulWidget {
  final void Function(double lat, double lon, String? address)? onLocationSelected;
  final double? initialLat;
  final double? initialLon;

  const GoogleLocationPicker({
    super.key,
    this.onLocationSelected,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<GoogleLocationPicker> createState() => _GoogleLocationPickerState();
}

class _GoogleLocationPickerState extends State<GoogleLocationPicker> {
  final String? _apiKey = const String.fromEnvironment('GMAPS_API_KEY');

  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedAddress;

  // Autocomplete state
  final TextEditingController _searchCtrl = TextEditingController();
  List<_PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _isLocatingMe = false;

  @override
  void initState() {
    super.initState();
    // Print API key for debugging
    print('API Key: ${_apiKey ?? "NOT SET"}');
    // Don't set default location yet - wait for user location
    _selectedLat = widget.initialLat;
    _selectedLon = widget.initialLon;
    // Auto-request location on init
    _requestLocationPermissionAndUse();
  }

  Future<void> _requestLocationPermissionAndUse() async {
    if (_isLocatingMe) return;
    setState(() => _isLocatingMe = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _selectedLat = pos.latitude;
            _selectedLon = pos.longitude;
          });
          // Wait a frame for the map to be ready
          await Future.delayed(const Duration(milliseconds: 100));
          if (_controller != null) {
            _controller!.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 17),
            );
          }
          _setMarker(pos.latitude, pos.longitude);
          await _reverseGeocode(pos.latitude, pos.longitude);
          print('Location set to: ${pos.latitude}, ${pos.longitude}');
        }
      } else {
        // Permission denied, use default
        if (mounted) {
          setState(() {
            _selectedLat = 14.5995;
            _selectedLon = 120.9842;
          });
          _setMarker(14.5995, 120.9842);
          _reverseGeocode(14.5995, 120.9842);
        }
      }
    } catch (e) {
      print('Location error: $e');
      // Use default location on error
      if (mounted) {
        setState(() {
          _selectedLat = 14.5995;
          _selectedLon = 120.9842;
        });
        _setMarker(14.5995, 120.9842);
        _reverseGeocode(14.5995, 120.9842);
      }
    } finally {
      if (mounted) setState(() => _isLocatingMe = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setMarker(double lat, double lon) {
    final marker = Marker(
      markerId: const MarkerId('selected'),
      position: LatLng(lat, lon),
      infoWindow: const InfoWindow(title: 'Selected Location'),
    );
    setState(() {
      _markers
        ..clear()
        ..add(marker);
      _selectedLat = lat;
      _selectedLon = lon;
    });
  }

  Future<void> _onMapTap(LatLng pos) async {
    _setMarker(pos.latitude, pos.longitude);
    await _reverseGeocode(pos.latitude, pos.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=${_apiKey!}',
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? [];
        final formatted = results.isNotEmpty ? results.first['formatted_address'] as String? : null;
        setState(() {
          _selectedAddress = formatted;
        });
        widget.onLocationSelected?.call(lat, lon, formatted);
      }
    } catch (_) {
      // ignore network errors
    }
  }

  Future<void> _onSearchChanged(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loadingSuggestions = true);
    
    // Use Nominatim (OpenStreetMap) for search - it's CORS-enabled and free
    final searchQuery = Uri.encodeComponent(text);
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=5',
    );
    print('Searching for: $text');
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'AgriSynch-App'},
      );
      print('Search response status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final List<dynamic> results = json.decode(res.body) as List<dynamic>;
        print('Results found: ${results.length}');
        final sug = results.map<_PlaceSuggestion>((r) {
          final address = r['display_name'] as String? ?? '';
          return _PlaceSuggestion(
            description: address,
            placeId: r['place_id'].toString(),
            lat: double.tryParse(r['lat'].toString()),
            lon: double.tryParse(r['lon'].toString()),
          );
        }).toList();
        if (mounted) {
          setState(() => _suggestions = sug);
        }
      } else {
        print('Search failed with status ${res.statusCode}');
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestions = false);
      }
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    setState(() => _suggestions = []);
    _searchCtrl.text = s.description;
    
    // Use the coordinates from Nominatim directly
    if (s.lat != null && s.lon != null) {
      _setMarker(s.lat!, s.lon!);
      await _reverseGeocode(s.lat!, s.lon!);
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(s.lat!, s.lon!), 17),
        );
      }
      print('Selected location: ${s.description} (${s.lat}, ${s.lon})');
    } else {
      print('No coordinates available for suggestion');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = CameraPosition(
      target: LatLng(_selectedLat ?? 14.5995, _selectedLon ?? 120.9842),
      zoom: 15,
    );

    return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initial,
            markers: _markers,
            onMapCreated: (c) => _controller = c,
            onTap: (pos) => _onMapTap(pos),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: true,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF37474F), width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search address...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF78909C),
                        ),
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF1DBF73)),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF64B5A6)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _suggestions = []);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        filled: true,
                        fillColor: const Color(0xFF263238),
                      ),
                      onChanged: (text) {
                        setState(() {}); // Trigger rebuild for clear button
                        _onSearchChanged(text);
                      },
                    ),
                  ),
                ),
                if (_loadingSuggestions)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Color(0xFF37474F),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DBF73)),
                    ),
                  ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF37474F)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF37474F)),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1DBF73)),
                          title: Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          onTap: () {
                            print('Tapped suggestion: ${s.description}');
                            _selectSuggestion(s);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: const Color(0xFF1A2332),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAddress ?? 'Tap the map or search to pick an address',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLat != null && _selectedLon != null
                          ? 'Lat: ${_selectedLat!.toStringAsFixed(6)}, Lng: ${_selectedLon!.toStringAsFixed(6)}'
                          : 'No location selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

class _PlaceSuggestion {
  final String description;
  final String placeId;
  final double? lat;
  final double? lon;
  
  _PlaceSuggestion({
    required this.description,
    required this.placeId,
    this.lat,
    this.lon,
  });
}

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class GoogleLocationPickerPage extends StatefulWidget {
  const GoogleLocationPickerPage({super.key});

  @override
  State<GoogleLocationPickerPage> createState() => _GoogleLocationPickerPageState();
}

class _GoogleLocationPickerPageState extends State<GoogleLocationPickerPage> {
  late GoogleLocationPicker _picker;
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _picker = GoogleLocationPicker(
      onLocationSelected: (lat, lon, address) {
        setState(() {
          _selectedLat = lat;
          _selectedLon = lon;
          _selectedAddress = address;
        });
      },
    );
  }

  void _confirmLocation() {
    if (_selectedLat != null && _selectedLon != null && _selectedAddress != null) {
      Navigator.pop(
        context,
        LocationPickerResult(
          latitude: _selectedLat!,
          longitude: _selectedLon!,
          address: _selectedAddress!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2332),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _picker,
      floatingActionButton: _selectedLat != null
          ? FloatingActionButton(
              onPressed: _confirmLocation,
              backgroundColor: const Color(0xFF1DBF73),
              child: const Icon(Icons.check),
            )
          : null,
    );
  }
}
