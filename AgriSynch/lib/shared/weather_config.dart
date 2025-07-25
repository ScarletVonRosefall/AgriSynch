// weather_config.dart
// Weather API Configuration

class WeatherConfig {
  // To get a free OpenWeatherMap API key:
  // 1. Go to https://openweathermap.org/api
  // 2. Sign up for a free account
  // 3. Go to your API keys section
  // 4. Copy your API key and paste it below
  
  static const String openWeatherMapApiKey = '';
  
  // You can also add other weather service APIs here in the future
  static const String weatherApiKey = '';
  static const String accuWeatherApiKey = '';
  
  // Helper method to check if API key is configured
  static bool get hasApiKey => openWeatherMapApiKey.isNotEmpty;
  
  // Instructions for getting API key
  static String get apiKeyInstructions => '''
🌤️ To get real weather data for Manila:

1. Visit: https://openweathermap.org/api
2. Click "Sign Up" (it's free!)
3. Verify your email
4. Go to "API keys" in your dashboard
5. Copy your API key
6. Paste it in lib/weather_config.dart

The app will use mock data until you add a real API key.
  ''';
}
