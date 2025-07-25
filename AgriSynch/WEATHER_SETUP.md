# Weather API Setup Guide

## Getting Your Free OpenWeatherMap API Key

1. **Visit OpenWeatherMap**: Go to https://openweathermap.org/api
2. **Sign Up**: Create a free account if you don't have one
3. **Get API Key**: 
   - Go to your account dashboard
   - Find the "API Keys" section
   - Copy your default API key
4. **Activate Key**: It may take up to 2 hours for your API key to be activated

## Setup Instructions

1. **Open the file**: `lib/api_config.dart`
2. **Replace API Key**: Change `'YOUR_API_KEY_HERE'` to your actual API key
3. **Save the file**

## Features

- **Real-time Weather**: Get current weather for your location
- **Location-based**: Automatically detects your current location
- **Fallback System**: Shows mock data if API fails or location is unavailable
- **Farming Advice**: Provides agricultural advice based on weather conditions

## Permissions

The app will request location permissions to get weather for your exact location. You can:
- **Allow**: Get weather for your current location
- **Deny**: The app will fall back to mock weather data

## Troubleshooting

- If weather shows "Loading..." indefinitely, check your internet connection
- If location permission is denied, the app will use mock data
- API key activation can take up to 2 hours after signing up
- Free API allows 1000 requests per day (more than enough for normal use)

## API Limits

- **Free Tier**: 1,000 API calls per day
- **Rate Limit**: 60 calls per minute
- **Data**: Current weather data only (no forecasts in free tier)
