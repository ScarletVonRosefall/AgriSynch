import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherHelper {
  // Open-Meteo API - No API key required! 🎉
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  static Future<WeatherData?> getCurrentWeather({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    try {
      // If city name is provided, get coordinates first
      if (cityName != null) {
        final coords = await _getCityCoordinates(cityName);
        if (coords != null) {
          lat = coords['latitude'];
          lon = coords['longitude'];
        } else {
          throw Exception('City not found: $cityName');
        }
      }

      // If no coordinates provided, get current location
      if (lat == null || lon == null) {
        print('No coordinates provided, requesting device location...');
        try {
          final position = await _getCurrentPosition();
          lat = position.latitude;
          lon = position.longitude;
          print('Using device location: $lat, $lon');
        } catch (e) {
          throw Exception('Unable to get location: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }

      // Build Open-Meteo API URL
      final url = '$_baseUrl?'
          'latitude=$lat&'
          'longitude=$lon&'
          'current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,apparent_temperature&'
          'timezone=auto';

      print('Making Open-Meteo API request to: $url');

      // Make API request (no API key needed!)
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print('Weather API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Weather data received: ${data['current']['temperature_2m']}°C');
        
        // Get location name from reverse geocoding with better fallback
        String locationName = await _getLocationName(lat, lon) ?? 
                             _getApproximateLocation(lat, lon);
        
        print('Location name: $locationName');
        
        return WeatherData.fromOpenMeteo(data, locationName);
      } else {
        throw Exception('Weather API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Weather API Exception: $e');
      rethrow;
    }
  }

  // Get approximate location name based on coordinates (fallback)
  static String _getApproximateLocation(double lat, double lon) {
    // Philippines regions based on coordinates
    if (lat >= 14.0 && lat <= 15.0 && lon >= 120.0 && lon <= 121.5) {
      return 'Metro Manila Area, Philippines';
    } else if (lat >= 10.0 && lat <= 11.0 && lon >= 123.5 && lon <= 124.5) {
      return 'Cebu Area, Philippines';
    } else if (lat >= 6.5 && lat <= 7.5 && lon >= 125.0 && lon <= 126.0) {
      return 'Davao Area, Philippines';
    } else if (lat >= 15.0 && lat <= 19.0 && lon >= 120.0 && lon <= 122.0) {
      return 'Northern Luzon, Philippines';
    } else if (lat >= 12.0 && lat <= 14.0 && lon >= 120.0 && lon <= 122.0) {
      return 'Central Luzon, Philippines';
    } else if (lat >= 10.0 && lat <= 13.0 && lon >= 122.0 && lon <= 126.0) {
      return 'Visayas Region, Philippines';
    } else if (lat >= 5.0 && lat <= 10.0 && lon >= 124.0 && lon <= 127.0) {
      return 'Mindanao Region, Philippines';
    }
    
    // Generic fallback with coordinates
    return 'Lat ${lat.toStringAsFixed(2)}°, Lon ${lon.toStringAsFixed(2)}°';
  }

  // Get coordinates from city name using Open-Meteo Geocoding API
  static Future<Map<String, double>?> _getCityCoordinates(String cityName) async {
    try {
      final url = '$_geocodingUrl?name=$cityName&count=1&language=en&format=json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return {
            'latitude': (result['latitude'] as num).toDouble(),
            'longitude': (result['longitude'] as num).toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  // Get location name from coordinates
  static Future<String?> _getLocationName(double lat, double lon) async {
    try {
      // Use Open-Meteo's reverse geocoding (correct endpoint)
      final url = 'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&count=1';
      print('Requesting location name from: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Geocoding response: $data');
        
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final city = result['name'] ?? '';
          final admin1 = result['admin1'] ?? '';
          final country = result['country'] ?? '';
          
          // Build location string from available parts
          List<String> parts = [];
          if (city.isNotEmpty) parts.add(city);
          if (admin1.isNotEmpty && admin1 != city) parts.add(admin1);
          if (country.isNotEmpty) parts.add(country);
          
          if (parts.isNotEmpty) {
            String location = parts.join(', ');
            print('Location resolved: $location');
            return location;
          }
        }
      }
      
      print('Geocoding returned no results or error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  static Future<Position> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        throw Exception('Location services are disabled. Please enable GPS in your device settings.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          throw Exception('Location permission denied. Please allow location access to get accurate weather.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        throw Exception('Location permission permanently denied. Please enable in device settings.');
      }

      print('Getting current position with high accuracy...');
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Location acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  static String getWeatherIcon(String iconCode) {
    // Map Open-Meteo WMO Weather codes to icons
    // See: https://open-meteo.com/en/docs
    final code = int.tryParse(iconCode) ?? 0;
    
    if (code == 0) return '☀️'; // Clear sky
    if (code >= 1 && code <= 3) return '⛅'; // Mainly clear, partly cloudy
    if (code >= 45 && code <= 48) return '🌫️'; // Fog
    if (code >= 51 && code <= 55) return '🌦️'; // Drizzle
    if (code >= 56 && code <= 57) return '🌧️'; // Freezing drizzle
    if (code >= 61 && code <= 65) return '🌧️'; // Rain
    if (code >= 66 && code <= 67) return '🌧️'; // Freezing rain
    if (code >= 71 && code <= 75) return '❄️'; // Snow fall
    if (code == 77) return '❄️'; // Snow grains
    if (code >= 80 && code <= 82) return '🌧️'; // Rain showers
    if (code >= 85 && code <= 86) return '❄️'; // Snow showers
    if (code >= 95 && code <= 99) return '⛈️'; // Thunderstorm
    
    return '🌤️'; // Default
  }

  static String _getWeatherDescription(int code) {
    // Convert WMO code to human-readable description
    if (code == 0) return 'Clear sky';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 56 && code <= 57) return 'Freezing drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 66 && code <= 67) return 'Freezing rain';
    if (code >= 71 && code <= 75) return 'Snow fall';
    if (code == 77) return 'Snow grains';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 85 && code <= 86) return 'Snow showers';
    if (code == 95) return 'Thunderstorm';
    if (code >= 96 && code <= 99) return 'Thunderstorm with hail';
    
    return 'Unknown';
  }

  static String getWeatherAdvice(String description, double temperature) {
    final desc = description.toLowerCase();

    if (desc.contains('rain') || desc.contains('shower')) {
      return 'Good day for indoor farm work';
    } else if (desc.contains('sun') || desc.contains('clear')) {
      if (temperature > 30) {
        return 'Hot day - ensure adequate irrigation';
      } else {
        return 'Perfect weather for farming';
      }
    } else if (desc.contains('cloud')) {
      return 'Mild conditions for outdoor work';
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return 'Stay indoors - protect crops';
    } else {
      return 'Check weather conditions regularly';
    }
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final String location;
  final String icon;
  final double feelsLike;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    required this.icon,
    required this.feelsLike,
  });

  // Factory for Open-Meteo API response
  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json, String locationName) {
    final current = json['current'];
    final weatherCode = current['weather_code'] as int;
    
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      description: WeatherHelper._getWeatherDescription(weatherCode),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      location: locationName,
      icon: weatherCode.toString(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
    );
  }

  String get temperatureString => '${temperature.round()}°C';
  String get feelsLikeString => '${feelsLike.round()}°C';
  String get capitalizedDescription => description
      .split(' ')
      .map(
        (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}
