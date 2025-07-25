class ApiConfig {
  // OpenWeatherMap API Configuration
  // 
  // STEP 1: Get your free API key:
  // 1. Go to: https://openweathermap.org/api
  // 2. Click "Sign Up" and create a free account
  // 3. Verify your email address
  // 4. Go to your dashboard and find "API keys"
  // 5. Copy your API key
  //
  // STEP 2: Replace 'YOUR_API_KEY_HERE' below with your actual API key
  // Note: It may take up to 2 hours for new API keys to be activated
  
  static const String openWeatherApiKey = '24db32438184d6c41e3240aad69d4e61';
  
  // Instructions:
  // 1. Replace the line above with: 
  //    static const String openWeatherApiKey = 'your_actual_api_key_from_openweathermap';
  // 2. Save this file
  // 3. Restart the app
  
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';
}
