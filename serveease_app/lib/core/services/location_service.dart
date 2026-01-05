// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationSuggestion {
  final String name;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  LocationSuggestion({
    required this.name,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  @override
  String toString() => name;
}

class LocationService {
  // Ethiopian cities and locations for autocomplete
  static final List<LocationSuggestion> ethiopianLocations = [
    LocationSuggestion(name: 'Addis Ababa', fullAddress: 'Addis Ababa, Ethiopia', latitude: 9.0320, longitude: 38.7469),
    LocationSuggestion(name: 'Dire Dawa', fullAddress: 'Dire Dawa, Ethiopia', latitude: 9.5931, longitude: 41.8661),
    LocationSuggestion(name: 'Mekelle', fullAddress: 'Mekelle, Tigray, Ethiopia', latitude: 13.4967, longitude: 39.4753),
    LocationSuggestion(name: 'Gondar', fullAddress: 'Gondar, Amhara, Ethiopia', latitude: 12.6090, longitude: 37.4671),
    LocationSuggestion(name: 'Awassa', fullAddress: 'Awassa, SNNPR, Ethiopia', latitude: 7.0621, longitude: 38.4970),
    LocationSuggestion(name: 'Bahir Dar', fullAddress: 'Bahir Dar, Amhara, Ethiopia', latitude: 11.5942, longitude: 37.3906),
    LocationSuggestion(name: 'Dessie', fullAddress: 'Dessie, Amhara, Ethiopia', latitude: 11.1300, longitude: 39.6333),
    LocationSuggestion(name: 'Jimma', fullAddress: 'Jimma, Oromia, Ethiopia', latitude: 7.6667, longitude: 36.8333),
    LocationSuggestion(name: 'Jijiga', fullAddress: 'Jijiga, Somali, Ethiopia', latitude: 9.3500, longitude: 42.8000),
    LocationSuggestion(name: 'Shashamane', fullAddress: 'Shashamane, Oromia, Ethiopia', latitude: 7.2000, longitude: 38.6000),
    LocationSuggestion(name: 'Arba Minch', fullAddress: 'Arba Minch, SNNPR, Ethiopia', latitude: 6.0333, longitude: 37.5500),
    LocationSuggestion(name: 'Harar', fullAddress: 'Harar, Harari, Ethiopia', latitude: 9.3100, longitude: 42.1200),
    LocationSuggestion(name: 'Debre Markos', fullAddress: 'Debre Markos, Amhara, Ethiopia', latitude: 10.3500, longitude: 37.7333),
    LocationSuggestion(name: 'Nekemte', fullAddress: 'Nekemte, Oromia, Ethiopia', latitude: 9.0833, longitude: 36.5500),
    LocationSuggestion(name: 'Debre Birhan', fullAddress: 'Debre Birhan, Amhara, Ethiopia', latitude: 9.6833, longitude: 39.5333),
    LocationSuggestion(name: 'Asella', fullAddress: 'Asella, Oromia, Ethiopia', latitude: 7.9500, longitude: 39.1333),
    LocationSuggestion(name: 'Kombolcha', fullAddress: 'Kombolcha, Amhara, Ethiopia', latitude: 11.0833, longitude: 39.7333),
    LocationSuggestion(name: 'Debre Zeit', fullAddress: 'Debre Zeit, Oromia, Ethiopia', latitude: 8.7500, longitude: 38.9833),
    LocationSuggestion(name: 'Adama', fullAddress: 'Adama (Nazret), Oromia, Ethiopia', latitude: 8.5500, longitude: 39.2667),
    LocationSuggestion(name: 'Wolkite', fullAddress: 'Wolkite, SNNPR, Ethiopia', latitude: 8.2833, longitude: 37.7667),
    LocationSuggestion(name: 'Hawassa', fullAddress: 'Hawassa, SNNPR, Ethiopia', latitude: 7.0621, longitude: 38.4970),
    LocationSuggestion(name: 'Dilla', fullAddress: 'Dilla, SNNPR, Ethiopia', latitude: 6.4167, longitude: 38.3167),
    LocationSuggestion(name: 'Hosanna', fullAddress: 'Hosanna, SNNPR, Ethiopia', latitude: 7.5500, longitude: 37.8500),
    LocationSuggestion(name: 'Wolaita Sodo', fullAddress: 'Wolaita Sodo, SNNPR, Ethiopia', latitude: 6.8167, longitude: 37.7500),
    LocationSuggestion(name: 'Bonga', fullAddress: 'Bonga, SNNPR, Ethiopia', latitude: 7.2833, longitude: 36.2333),
  ];

  /// Search for locations based on query
  static List<LocationSuggestion> searchLocations(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return ethiopianLocations.where((location) {
      return location.name.toLowerCase().contains(lowerQuery) ||
             location.fullAddress.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get current GPS location
  static Future<LocationResult> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Location permission permanently denied. Please enable in settings.');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled. Please enable location services.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final suggestion = LocationSuggestion(
        name: 'Current Location',
        fullAddress: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return LocationResult.success(suggestion, position);
    } catch (e) {
      return LocationResult.error('Failed to get location: ${e.toString()}');
    }
  }
}

class LocationResult {
  final bool success;
  final String? error;
  final LocationSuggestion? suggestion;
  final Position? position;

  LocationResult._({
    required this.success,
    this.error,
    this.suggestion,
    this.position,
  });

  factory LocationResult.success(LocationSuggestion suggestion, Position position) {
    return LocationResult._(
      success: true,
      suggestion: suggestion,
      position: position,
    );
  }

  factory LocationResult.error(String error) {
    return LocationResult._(
      success: false,
      error: error,
    );
  }
}