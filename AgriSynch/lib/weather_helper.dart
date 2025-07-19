import 'dart:math';

class WeatherHelper {
  static Future<WeatherData?> getCurrentWeather({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    // For development, return randomized mock data
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    return _getRandomWeatherData();
  }
  
  // Mock weather data that changes slightly each time
  static WeatherData _getRandomWeatherData() {
    final random = Random();
    final baseTemp = 26 + random.nextDouble() * 8; // 26-34°C range
    final weatherTypes = [
      {'desc': 'Sunny', 'icon': '01d'},
      {'desc': 'Partly Cloudy', 'icon': '02d'},
      {'desc': 'Cloudy', 'icon': '03d'},
      {'desc': 'Light Rain', 'icon': '09d'},
      {'desc': 'Clear Sky', 'icon': '01d'},
    ];
    
    final weather = weatherTypes[random.nextInt(weatherTypes.length)];
    
    return WeatherData(
      temperature: double.parse(baseTemp.toStringAsFixed(1)),
      description: weather['desc']!,
      humidity: 65 + random.nextInt(25), // 65-90%
      windSpeed: 5 + random.nextDouble() * 15, // 5-20 km/h
      location: 'Manila, PH',
      icon: weather['icon']!,
      feelsLike: baseTemp + random.nextDouble() * 3,
    );
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
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      location: '${json['name']}, ${json['sys']['country']}',
      icon: json['weather'][0]['icon'],
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
    );
  }
  
  String get temperatureString => '${temperature.round()}°C';
  String get feelsLikeString => '${feelsLike.round()}°C';
  String get capitalizedDescription => description.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
}
