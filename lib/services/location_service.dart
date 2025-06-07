import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/currency_provider.dart';
import 'dart:convert';
import 'dart:async';

class LocationService {
  static final Map<String, String> _countryToCurrency = {
    'Indonesia': 'ID',
    'United States': 'US',
    'Japan': 'JP',
    'United Kingdom': 'GB',
    'European Union': 'EU',
    'Australia': 'AU',
    'Singapore': 'SG',
    'Malaysia': 'MY',
  };

  // Cache keys
  static const String _cachedLocationKey = 'cached_location';
  static const String _locationTimestampKey = 'location_timestamp';
  // Cache duration - 5 minutes
  static const int _cacheDurationInMinutes = 5;

  static Future<Map<String, String>> getCurrentLocation(
    BuildContext context,
  ) async {
    try {
      // Always check location services first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 5),
        onTimeout:
            () => throw TimeoutException('Location service check timed out'),
      );

      if (!serviceEnabled) {
        _showSnackBar(
          context,
          'Location services are disabled. Please enable location services.',
        );
        return _getDefaultOrCachedLocation(
          await SharedPreferences.getInstance(),
        );
      }

      // Check and request permissions if needed
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
            context,
            'Location permissions denied. Please enable location permissions.',
          );
          return _getDefaultOrCachedLocation(
            await SharedPreferences.getInstance(),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          context,
          'Location permissions permanently denied. Please enable in settings.',
        );
        return _getDefaultOrCachedLocation(
          await SharedPreferences.getInstance(),
        );
      }

      // Get current position with high accuracy and no cache
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true, // This helps with fake GPS detection
        timeLimit: const Duration(seconds: 10),
      );

      // Try multiple geocoding services in order
      Map<String, String> locationData;
      Exception? lastError;

      try {
        // Try OpenStreetMap Nominatim first
        locationData = await _getAddressFromNominatim(position, context);
      } catch (e) {
        debugPrint('Nominatim geocoding failed: $e');
        try {
          // Fallback to custom geocoding service
          locationData = await _getAddressFromCustomService(position, context);
        } catch (e2) {
          debugPrint('Custom geocoding failed: $e2');
          lastError = Exception('All geocoding services failed');
          // Return coordinates as location if both services fail
          locationData = {
            'city':
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            'country': 'Unknown',
            'timezone': 'UTC',
            'error': '',
          };
        }
      }

      // Only cache if we got a proper country
      if (locationData['country'] != 'Unknown') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedLocationKey, json.encode(locationData));
        await prefs.setInt(
          _locationTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      return locationData;
    } catch (e) {
      debugPrint('Location error: $e');
      return _handleError(context, e);
    }
  }

  static Future<Map<String, String>> _getAddressFromNominatim(
    Position position,
    BuildContext context,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10',
            ),
            headers: {
              'User-Agent': 'PokemonTCG/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'] ??
              'Unknown City';
          final country = address['country'] ?? 'Unknown Country';

          // Get timezone from timezone API
          final timezone = await _getTimezoneFromCoordinates(
            position.latitude,
            position.longitude,
          );

          // Update currency based on country
          _updateCurrencyFromCountry(context, country);

          return {
            'city': city,
            'country': country,
            'timezone': timezone,
            'error': '',
          };
        }
      }
      throw Exception('Invalid response from Nominatim');
    } catch (e) {
      debugPrint('Nominatim error: $e');
      throw Exception('Nominatim geocoding failed: $e');
    }
  }

  static Future<String> _getTimezoneFromCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${dotenv.env['TIME_API_BASE_URL']}/timezone/position?latitude=$lat&longitude=$lon',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['timezone'] ?? 'UTC';
      }
      return 'UTC';
    } catch (e) {
      debugPrint('Timezone API error: $e');
      return 'UTC';
    }
  }

  static Future<Map<String, String>> _getAddressFromCustomService(
    Position position,
    BuildContext context,
  ) async {
    try {
      final baseUrl = dotenv.env['GEOCODING_API_URL'];
      if (baseUrl == null) {
        throw Exception('Geocoding API URL not configured');
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'] ??
              'Unknown City';
          final country = address['country'] ?? 'Unknown Country';

          // Get timezone from timezone API
          final timezone = await _getTimezoneFromCoordinates(
            position.latitude,
            position.longitude,
          );

          // Update currency based on country
          _updateCurrencyFromCountry(context, country);

          return {
            'city': city,
            'country': country,
            'timezone': timezone,
            'error': '',
          };
        }
      }
      throw Exception('Invalid response from custom geocoding service');
    } catch (e) {
      debugPrint('Custom geocoding error: $e');
      throw Exception('Custom geocoding failed: $e');
    }
  }

  static Future<Map<String, String>> _getDefaultOrCachedLocation(
    SharedPreferences prefs,
  ) async {
    final cachedLocation = prefs.getString(_cachedLocationKey);
    final cachedTimestamp = prefs.getInt(_locationTimestampKey);

    if (cachedLocation != null && cachedTimestamp != null) {
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cachedTimestamp),
      );

      if (cacheAge.inMinutes < _cacheDurationInMinutes) {
        return Map<String, String>.from(json.decode(cachedLocation));
      }
    }
    return {
      'city': 'Unknown City',
      'country': 'United States',
      'timezone': 'UTC',
      'error': '',
    };
  }

  static void _updateCurrencyFromCountry(BuildContext context, String country) {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final countryCode = _countryToCurrency[country] ?? 'US';
    currencyProvider.setCountry(countryCode);
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<Map<String, String>> _handleError(
    BuildContext context,
    dynamic error,
  ) async {
    debugPrint('Location service error: $error');
    final prefs = await SharedPreferences.getInstance();
    _showSnackBar(
      context,
      'Location detection failed. Please check your location settings.',
    );
    return _getDefaultOrCachedLocation(prefs);
  }
}
