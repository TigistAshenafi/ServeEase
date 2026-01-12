// lib/core/services/google_maps_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../config/api_config.dart';

class GoogleMapsService {
  static final Logger _logger = Logger('GoogleMapsService');
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Get detailed address from coordinates using Google Maps Geocoding API
  static Future<GoogleMapsResult> getAddressFromCoordinates(
    double latitude, 
    double longitude
  ) async {
    try {
      // Check if API key is configured
      if (!ApiConfig.hasValidApiKey) {
        _logger.warning('Google Maps API key not configured');
        return GoogleMapsResult.error('Google Maps API key not configured. Please add your API key in ApiConfig.');
      }

      _logger.info('Getting address from Google Maps API...');
      _logger.fine('Coordinates: $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl?latlng=$latitude,$longitude&key=${ApiConfig.googleMapsApiKey}&language=en'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          return _parseGoogleMapsResponse(data['results'], latitude, longitude);
        } else {
          _logger.severe('Google Maps API error: ${data['status']}');
          if (data['error_message'] != null) {
            _logger.severe('Error message: ${data['error_message']}');
          }
          return GoogleMapsResult.error('Google Maps API returned: ${data['status']}');
        }
      } else {
        _logger.severe('HTTP error: ${response.statusCode}');
        return GoogleMapsResult.error('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Google Maps API error: $e');
      return GoogleMapsResult.error('Failed to get address: $e');
    }
  }

  /// Parse Google Maps API response to extract detailed location info
  static GoogleMapsResult _parseGoogleMapsResponse(
    List<dynamic> results, 
    double latitude, 
    double longitude
  ) {
    _logger.fine('Parsing ${results.length} Google Maps results...');

    if (results.isNotEmpty) {
      final result = results[0]; // Use the first (most accurate) result
      _logger.fine('--- Result 0 ---');
      _logger.fine('Formatted Address: ${result['formatted_address']}');
      _logger.fine('Types: ${result['types']}');

      // Extract address components
      final components = result['address_components'] as List<dynamic>? ?? [];
      final addressInfo = _extractAddressComponents(components);
      
      // Get formatted address
      String formattedAddress = result['formatted_address'] ?? '';
      
      // Create detailed location info
      String locationName = _buildLocationName(addressInfo, formattedAddress);
      String fullAddress = _buildFullAddress(addressInfo, formattedAddress);
      
      _logger.fine('Built Location Name: "$locationName"');
      _logger.fine('Built Full Address: "$fullAddress"');

      // Return the first (most accurate) result
      return GoogleMapsResult.success(
        GoogleMapsLocation(
          name: locationName,
          fullAddress: fullAddress,
          formattedAddress: formattedAddress,
          streetNumber: addressInfo['street_number'],
          streetName: addressInfo['route'],
          neighborhood: addressInfo['sublocality'] ?? addressInfo['neighborhood'],
          city: addressInfo['locality'],
          district: addressInfo['sublocality_level_1'],
          region: addressInfo['administrative_area_level_1'],
          country: addressInfo['country'],
          postalCode: addressInfo['postal_code'],
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    return GoogleMapsResult.error('No valid address found in Google Maps results');
  }

  /// Extract address components from Google Maps response
  static Map<String, String> _extractAddressComponents(List<dynamic> components) {
    Map<String, String> addressInfo = {};

    for (final component in components) {
      final types = component['types'] as List<dynamic>? ?? [];
      final longName = component['long_name'] as String? ?? '';
      // Note: shortName available but not used in current implementation

      for (final type in types) {
        switch (type) {
          case 'street_number':
            addressInfo['street_number'] = longName;
            break;
          case 'route':
            addressInfo['route'] = longName;
            break;
          case 'neighborhood':
            addressInfo['neighborhood'] = longName;
            break;
          case 'sublocality':
          case 'sublocality_level_1':
            addressInfo['sublocality'] = longName;
            break;
          case 'sublocality_level_2':
            addressInfo['sublocality_level_2'] = longName;
            break;
          case 'locality':
            addressInfo['locality'] = longName;
            break;
          case 'administrative_area_level_1':
            addressInfo['administrative_area_level_1'] = longName;
            break;
          case 'administrative_area_level_2':
            addressInfo['administrative_area_level_2'] = longName;
            break;
          case 'country':
            addressInfo['country'] = longName;
            break;
          case 'postal_code':
            addressInfo['postal_code'] = longName;
            break;
        }
      }
    }

    return addressInfo;
  }

  /// Build a specific location name from address components
  static String _buildLocationName(Map<String, String> addressInfo, String formattedAddress) {
    // Priority order for location name
    List<String> nameParts = [];

    // Add street with number if available
    if (addressInfo['route'] != null && addressInfo['route']!.isNotEmpty) {
      String streetName = addressInfo['route']!;
      if (addressInfo['street_number'] != null && addressInfo['street_number']!.isNotEmpty) {
        streetName = '${addressInfo['street_number']} $streetName';
      }
      nameParts.add(streetName);
    }

    // Add neighborhood/area
    if (addressInfo['neighborhood'] != null && addressInfo['neighborhood']!.isNotEmpty) {
      nameParts.add(addressInfo['neighborhood']!);
    } else if (addressInfo['sublocality'] != null && addressInfo['sublocality']!.isNotEmpty) {
      nameParts.add(addressInfo['sublocality']!);
    }

    // If we have specific parts, use them
    if (nameParts.isNotEmpty) {
      return nameParts.join(', ');
    }

    // Fallback to city or first part of formatted address
    if (addressInfo['locality'] != null && addressInfo['locality']!.isNotEmpty) {
      return addressInfo['locality']!;
    }

    // Last resort: use first part of formatted address
    List<String> addressParts = formattedAddress.split(',');
    if (addressParts.isNotEmpty) {
      return addressParts.first.trim();
    }

    return 'Current Location';
  }

  /// Build full address from components
  static String _buildFullAddress(Map<String, String> addressInfo, String formattedAddress) {
    // Use Google's formatted address as it's usually well-formatted
    if (formattedAddress.isNotEmpty) {
      return formattedAddress;
    }

    // Fallback: build from components
    List<String> addressParts = [];

    if (addressInfo['street_number'] != null && addressInfo['route'] != null) {
      addressParts.add('${addressInfo['street_number']} ${addressInfo['route']}');
    } else if (addressInfo['route'] != null) {
      addressParts.add(addressInfo['route']!);
    }

    if (addressInfo['neighborhood'] != null) {
      addressParts.add(addressInfo['neighborhood']!);
    }

    if (addressInfo['locality'] != null) {
      addressParts.add(addressInfo['locality']!);
    }

    if (addressInfo['administrative_area_level_1'] != null) {
      addressParts.add(addressInfo['administrative_area_level_1']!);
    }

    if (addressInfo['country'] != null) {
      addressParts.add(addressInfo['country']!);
    }

    return addressParts.join(', ');
  }
}

/// Google Maps location result
class GoogleMapsLocation {
  final String name;
  final String fullAddress;
  final String formattedAddress;
  final String? streetNumber;
  final String? streetName;
  final String? neighborhood;
  final String? city;
  final String? district;
  final String? region;
  final String? country;
  final String? postalCode;
  final double latitude;
  final double longitude;

  GoogleMapsLocation({
    required this.name,
    required this.fullAddress,
    required this.formattedAddress,
    this.streetNumber,
    this.streetName,
    this.neighborhood,
    this.city,
    this.district,
    this.region,
    this.country,
    this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => name;
}

/// Google Maps API result wrapper
class GoogleMapsResult {
  final bool success;
  final String? error;
  final GoogleMapsLocation? location;

  GoogleMapsResult._({
    required this.success,
    this.error,
    this.location,
  });

  factory GoogleMapsResult.success(GoogleMapsLocation location) {
    return GoogleMapsResult._(
      success: true,
      location: location,
    );
  }

  factory GoogleMapsResult.error(String error) {
    return GoogleMapsResult._(
      success: false,
      error: error,
    );
  }
}