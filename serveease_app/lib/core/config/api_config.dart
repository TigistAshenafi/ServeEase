// lib/core/config/api_config.dart
class ApiConfig {
  // Google Maps API Configuration
  // To get your API key:
  // 1. Go to https://console.cloud.google.com/
  // 2. Create a new project or select existing one
  // 3. Enable "Geocoding API" 
  // 4. Create credentials (API Key)
  // 5. Replace the key below
  
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  // For development/testing, you can use a placeholder
  // But for production, you MUST use a real API key
  static bool get hasValidApiKey => googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
}