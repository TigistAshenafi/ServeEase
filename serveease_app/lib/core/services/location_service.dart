// lib/core/services/location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

import 'google_maps_service.dart';

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
  static final Logger _logger = Logger('LocationService');
  // Ethiopian cities and locations for autocomplete and fallback
  static final List<LocationSuggestion> ethiopianLocations = [
    // Major cities
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
    
    // Additional cities for better coverage
    LocationSuggestion(name: 'Axum', fullAddress: 'Axum, Tigray, Ethiopia', latitude: 14.1306, longitude: 38.7225),
    LocationSuggestion(name: 'Lalibela', fullAddress: 'Lalibela, Amhara, Ethiopia', latitude: 12.0333, longitude: 39.0333),
    LocationSuggestion(name: 'Gambela', fullAddress: 'Gambela, Gambela, Ethiopia', latitude: 8.2500, longitude: 34.5833),
    LocationSuggestion(name: 'Assosa', fullAddress: 'Assosa, Benishangul-Gumuz, Ethiopia', latitude: 10.0667, longitude: 34.5333),
    LocationSuggestion(name: 'Semera', fullAddress: 'Semera, Afar, Ethiopia', latitude: 11.7833, longitude: 41.0056),
    
    // More regional cities
    LocationSuggestion(name: 'Woldiya', fullAddress: 'Woldiya, Amhara, Ethiopia', latitude: 11.8333, longitude: 39.6000),
    LocationSuggestion(name: 'Debre Tabor', fullAddress: 'Debre Tabor, Amhara, Ethiopia', latitude: 11.8500, longitude: 38.0167),
    LocationSuggestion(name: 'Finote Selam', fullAddress: 'Finote Selam, Amhara, Ethiopia', latitude: 10.7000, longitude: 37.2667),
    LocationSuggestion(name: 'Bichena', fullAddress: 'Bichena, Amhara, Ethiopia', latitude: 10.4500, longitude: 38.2000),
    LocationSuggestion(name: 'Kemise', fullAddress: 'Kemise, Amhara, Ethiopia', latitude: 10.7167, longitude: 39.8667),
    LocationSuggestion(name: 'Weldia', fullAddress: 'Weldia, Amhara, Ethiopia', latitude: 11.8333, longitude: 39.6000),
    LocationSuggestion(name: 'Sekota', fullAddress: 'Sekota, Amhara, Ethiopia', latitude: 12.6333, longitude: 39.0333),
    LocationSuggestion(name: 'Kobo', fullAddress: 'Kobo, Amhara, Ethiopia', latitude: 12.1500, longitude: 39.6333),
    LocationSuggestion(name: 'Alamata', fullAddress: 'Alamata, Tigray, Ethiopia', latitude: 12.4167, longitude: 39.5333),
    LocationSuggestion(name: 'Maychew', fullAddress: 'Maychew, Tigray, Ethiopia', latitude: 12.7833, longitude: 39.5417),
    LocationSuggestion(name: 'Shire', fullAddress: 'Shire, Tigray, Ethiopia', latitude: 14.1000, longitude: 38.2833),
    LocationSuggestion(name: 'Adigrat', fullAddress: 'Adigrat, Tigray, Ethiopia', latitude: 14.2667, longitude: 39.4667),
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

  /// Get current GPS location with precise address using Google Maps API
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

      _logger.info('Getting precise GPS position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      _logger.info('GPS Coordinates: ${position.latitude}, ${position.longitude}');
      _logger.info('Accuracy: ${position.accuracy}m');

      // First try: Use Google Maps API for precise location details
      _logger.info('Trying Google Maps API for precise location...');
      GoogleMapsResult googleResult = await GoogleMapsService.getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (googleResult.success && googleResult.location != null) {
        _logger.info('Google Maps API success: ${googleResult.location!.name}');
        
        final suggestion = LocationSuggestion(
          name: googleResult.location!.name,
          fullAddress: googleResult.location!.fullAddress,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        return LocationResult.success(suggestion, position);
      } else {
        _logger.warning('Google Maps API failed: ${googleResult.error}');
      }

      // Second try: Use built-in reverse geocoding
      _logger.info('Falling back to built-in geocoding...');
      String? cityName = await _getCityNameFromCoordinates(position);
      
      if (cityName != null && cityName.isNotEmpty) {
        _logger.info('Built-in geocoding success: $cityName');
        final suggestion = LocationSuggestion(
          name: cityName,
          fullAddress: '$cityName, Ethiopia',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        return LocationResult.success(suggestion, position);
      }

      // Third try: Find nearest Ethiopian city from our database
      _logger.info('Finding nearest Ethiopian city...');
      LocationSuggestion nearestCity = _findNearestEthiopianCity(position.latitude, position.longitude);
      
      _logger.info('Nearest city found: ${nearestCity.name}');
      return LocationResult.success(nearestCity, position);
      
    } catch (e) {
      _logger.severe('Location error: $e');
      return LocationResult.error('Failed to get location: ${e.toString()}');
    }
  }

  /// Get city name from coordinates using reverse geocoding
  static Future<String?> _getCityNameFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      _logger.info('Found ${placemarks.length} placemarks');

      for (int i = 0; i < placemarks.length; i++) {
        Placemark place = placemarks[i];
        
        _logger.fine('--- Placemark $i ---');
        _logger.fine('Locality: "${place.locality}"');
        _logger.fine('SubAdministrativeArea: "${place.subAdministrativeArea}"');
        _logger.fine('AdministrativeArea: "${place.administrativeArea}"');
        _logger.fine('Country: "${place.country}"');

        // Try to extract Ethiopian city name
        String? cityName = _extractEthiopianCityName(place);
        if (cityName != null) {
          // Validate that this city makes sense for the GPS coordinates
          if (_validateCityForCoordinates(cityName, position.latitude, position.longitude)) {
            _logger.info('Validated city: $cityName');
            return cityName;
          } else {
            _logger.warning('City $cityName doesn\'t match GPS coordinates, skipping');
          }
        }
      }

      _logger.warning('No valid Ethiopian city found in placemarks');
      return null;
    } catch (e) {
      _logger.severe('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Validate that the detected city makes sense for the given coordinates
  static bool _validateCityForCoordinates(String cityName, double latitude, double longitude) {
    // Find the city in our database
    LocationSuggestion? cityData = ethiopianLocations.firstWhere(
      (city) => city.name.toLowerCase() == cityName.toLowerCase(),
      orElse: () => LocationSuggestion(name: '', fullAddress: ''),
    );

    if (cityData.name.isEmpty || cityData.latitude == null || cityData.longitude == null) {
      _logger.warning('City $cityName not found in database, accepting anyway');
      return true; // Accept unknown cities
    }

    // Calculate distance between GPS and city center
    double distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      cityData.latitude!,
      cityData.longitude!,
    );

    double distanceKm = distance / 1000;
    _logger.fine('Distance from GPS to $cityName center: ${distanceKm.toStringAsFixed(1)}km');

    // Accept if within reasonable distance (50km for cities, 20km for smaller places)
    double maxDistance = cityName == 'Addis Ababa' ? 50.0 : 30.0;
    
    if (distanceKm <= maxDistance) {
      _logger.info('$cityName is valid (within ${maxDistance}km)');
      return true;
    } else {
      _logger.warning('$cityName is too far (${distanceKm.toStringAsFixed(1)}km > ${maxDistance}km)');
      return false;
    }
  }

  /// Extract Ethiopian city name from placemark
  static String? _extractEthiopianCityName(Placemark place) {
    // List of potential city name fields in priority order
    List<String?> cityFields = [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ];

    for (String? field in cityFields) {
      if (field != null && field.isNotEmpty) {
        String cleanName = field.trim();
        
        _logger.fine('Checking field: "$cleanName"');
        
        // Skip generic "Addis Ababa" results unless we're actually close to Addis Ababa
        if (cleanName.toLowerCase().contains('addis ababa')) {
          _logger.warning('Skipping generic "Addis Ababa" result');
          continue;
        }
        
        // Check if it's a known Ethiopian city
        if (_isKnownEthiopianCity(cleanName)) {
          _logger.info('Found known Ethiopian city: $cleanName');
          return cleanName;
        }
        
        // Check if it contains Ethiopian city name
        String? matchedCity = _findEthiopianCityInText(cleanName);
        if (matchedCity != null) {
          _logger.info('Found Ethiopian city in text: $matchedCity');
          return matchedCity;
        }
      }
    }

    _logger.warning('No Ethiopian city found in placemark');
    return null;
  }

  /// Check if the name is a known Ethiopian city
  static bool _isKnownEthiopianCity(String name) {
    String lowerName = name.toLowerCase();
    
    for (LocationSuggestion city in ethiopianLocations) {
      if (city.name.toLowerCase() == lowerName) {
        return true;
      }
    }
    
    return false;
  }

  /// Find Ethiopian city name within text
  static String? _findEthiopianCityInText(String text) {
    String lowerText = text.toLowerCase();
    
    for (LocationSuggestion city in ethiopianLocations) {
      String lowerCityName = city.name.toLowerCase();
      if (lowerText.contains(lowerCityName)) {
        return city.name;
      }
    }
    
    return null;
  }

  /// Find the nearest Ethiopian city based on GPS coordinates
  static LocationSuggestion _findNearestEthiopianCity(double latitude, double longitude) {
    double minDistance = double.infinity;
    LocationSuggestion nearestCity = ethiopianLocations.first;

    _logger.fine('Searching nearest city to: $latitude, $longitude');

    // Calculate distance to all cities
    List<MapEntry<LocationSuggestion, double>> cityDistances = [];

    for (final location in ethiopianLocations) {
      if (location.latitude != null && location.longitude != null) {
        double distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          location.latitude!,
          location.longitude!,
        );

        cityDistances.add(MapEntry(location, distance));

        _logger.fine('Distance to ${location.name}: ${(distance / 1000).toStringAsFixed(1)}km');

        if (distance < minDistance) {
          minDistance = distance;
          nearestCity = location;
        }
      }
    }

    // Sort by distance to see the closest cities
    cityDistances.sort((a, b) => a.value.compareTo(b.value));
    
    _logger.fine('Top 3 closest cities:');
    for (int i = 0; i < 3 && i < cityDistances.length; i++) {
      final entry = cityDistances[i];
      _logger.fine('  ${i + 1}. ${entry.key.name}: ${(entry.value / 1000).toStringAsFixed(1)}km');
    }

    _logger.info('Selected nearest city: ${nearestCity.name} (${(minDistance / 1000).toStringAsFixed(1)}km away)');

    // If the nearest city is very far (more than 100km), it might be inaccurate
    if (minDistance > 100000) { // 100km
      _logger.warning('Nearest city is ${(minDistance / 1000).toStringAsFixed(1)}km away - might be inaccurate');
      
      // Check if we're closer to any specific region
      if (latitude > 12.0) {
        // Northern Ethiopia - prefer northern cities
        for (final city in ['Mekelle', 'Gondar', 'Axum', 'Lalibela']) {
          final cityLocation = ethiopianLocations.firstWhere(
            (loc) => loc.name == city,
            orElse: () => nearestCity,
          );
          if (cityLocation != nearestCity) {
            _logger.info('In northern region, suggesting: $city');
            return LocationSuggestion(
              name: city,
              fullAddress: '$city, Ethiopia',
              latitude: latitude,
              longitude: longitude,
            );
          }
        }
      } else if (latitude < 7.0) {
        // Southern Ethiopia - prefer southern cities
        for (final city in ['Awassa', 'Arba Minch', 'Dilla']) {
          final cityLocation = ethiopianLocations.firstWhere(
            (loc) => loc.name == city,
            orElse: () => nearestCity,
          );
          if (cityLocation != nearestCity) {
            _logger.info('In southern region, suggesting: $city');
            return LocationSuggestion(
              name: city,
              fullAddress: '$city, Ethiopia',
              latitude: latitude,
              longitude: longitude,
            );
          }
        }
      }
    }

    // Return the nearest city with actual GPS coordinates
    return LocationSuggestion(
      name: nearestCity.name,
      fullAddress: nearestCity.fullAddress,
      latitude: latitude, // Use actual GPS coordinates
      longitude: longitude,
    );
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