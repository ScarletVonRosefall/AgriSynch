import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

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

class InteractiveLocationPickerPage extends StatefulWidget {
  const InteractiveLocationPickerPage({super.key});

  @override
  State<InteractiveLocationPickerPage> createState() =>
      _InteractiveLocationPickerPageState();
}

class _InteractiveLocationPickerPageState
    extends State<InteractiveLocationPickerPage> {
  late MapController _mapController;
  double? _selectedLat;
  double? _selectedLon;
  String _selectedAddress = 'Tap on map to select location';
  bool _isLoadingAddress = false;
  bool _isLocatingMe = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Default center: Manila, Philippines
    _selectedLat = 14.5995;
    _selectedLon = 120.9842;
  }

  Future<void> _updateAddress(double lat, double lon) async {
    setState(() => _isLoadingAddress = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['address']?['road'] ??
              data['address']?['neighbourhood'] ??
              data['address']?['suburb'] ??
              'Location selected';
        });
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
      setState(() {
        _selectedAddress = '$lat, $lon';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLat = position.latitude;
      _selectedLon = position.longitude;
    });
    _updateAddress(position.latitude, position.longitude);
  }

  void _confirmSelection() {
    if (_selectedLat != null && _selectedLon != null) {
      Navigator.pop(
        context,
        LocationPickerResult(
          latitude: _selectedLat!,
          longitude: _selectedLon!,
          address: _selectedAddress,
        ),
      );
    }
  }

  Future<void> _useMyLocation() async {
    try {
      setState(() => _isLocatingMe = true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please enable it in settings.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      setState(() {
        _selectedLat = lat;
        _selectedLon = lon;
      });

      // Center the map to user's location
      _mapController.move(LatLng(lat, lon), 16.0);

      // Update human-readable address
      await _updateAddress(lat, lon);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Centered to your current location')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingMe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  LatLng(_selectedLat ?? 14.5995, _selectedLon ?? 120.9842),
              initialZoom: 15.0,
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agrisynch',
              ),
              if (_selectedLat != null && _selectedLon != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_selectedLat!, _selectedLon!),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // My Location button (top-right)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _isLocatingMe ? null : _useMyLocation,
              child: _isLocatingMe
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          // Bottom sheet with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingAddress)
                    const SizedBox(
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_selectedLat?.toStringAsFixed(4)}, Lon: ${_selectedLon?.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
