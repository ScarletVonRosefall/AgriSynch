import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'api_config.dart';

class WeatherHelper {
  static Future<WeatherData?> getCurrentWeather({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    try {
      // Check if API key is configured
      if (ApiConfig.openWeatherApiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('Please set up your OpenWeatherMap API key:\n\n1. Go to: https://openweathermap.org/api\n2. Sign up for free\n3. Get your API key\n4. Update lib/api_config.dart\n5. Restart the app');
      }
      
      // If no coordinates provided, get current location
      if (lat == null || lon == null) {
        if (cityName == null) {
          final position = await _getCurrentPosition();
          if (position != null) {
            lat = position.latitude;
            lon = position.longitude;
          } else {
            // Fallback to Manila, Philippines for testing if location fails
            print('Location services failed, using Manila as test location');
            lat = 14.5995;
            lon = 120.9842;
          }
        }
      }
      
      // Build API URL
      String url;
      if (cityName != null) {
        url = '${ApiConfig.openWeatherBaseUrl}?q=$cityName&appid=${ApiConfig.openWeatherApiKey}&units=metric';
      } else {
        url = '${ApiConfig.openWeatherBaseUrl}?lat=$lat&lon=$lon&appid=${ApiConfig.openWeatherApiKey}&units=metric';
      }
      
      print('Using API key: ${ApiConfig.openWeatherApiKey}');
      print('Making weather API request to: $url');
      
      // Make API request
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      print('Weather API response status: ${response.statusCode}');
      print('Weather API response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Weather data received: ${data['name']}, ${data['main']['temp']}°C');
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        // API key issues
        final errorData = json.decode(response.body);
        if (errorData['message'].toString().toLowerCase().contains('invalid')) {
          throw Exception('API Key Error: Your API key "${ApiConfig.openWeatherApiKey}" is invalid. Please check it at https://openweathermap.org/api');
        } else {
          throw Exception('API Key Error: ${errorData['message']}. Your API key might not be activated yet (can take up to 2 hours).');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Location not found. Please check the city name or enable location services.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Weather API error (${response.statusCode}): ${errorData['message'] ?? response.body}');
      }
    } catch (e) {
      print('Weather API Exception: $e');
      rethrow; // Re-throw the exception instead of returning mock data
    }
  }
  
  static Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  
  static String getWeatherIcon(String iconCode) {
    // Map OpenWeatherMap icon codes to appropriate icons
    switch (iconCode) {
      case '01d': case '01n': // clear sky
        return '☀️';
      case '02d': case '02n': // few clouds
        return '⛅';
      case '03d': case '03n': // scattered clouds
        return '☁️';
      case '04d': case '04n': // broken clouds
        return '☁️';
      case '09d': case '09n': // shower rain
        return '🌦️';
      case '10d': case '10n': // rain
        return '🌧️';
      case '11d': case '11n': // thunderstorm
        return '⛈️';
      case '13d': case '13n': // snow
        return '❄️';
      case '50d': case '50n': // mist
        return '🌫️';
      default:
        return '🌤️';
    }
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
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble() * 3.6, // Convert m/s to km/h
      location: '${json['name']}, ${json['sys']['country']}',
      icon: json['weather'][0]['icon'] as String,
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
    );
  }
  
  String get temperatureString => '${temperature.round()}°C';
  String get feelsLikeString => '${feelsLike.round()}°C';
  String get capitalizedDescription => description.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
}
