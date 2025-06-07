import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimeService {
  static final Map<String, _CachedTime> _cache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static bool _initialized = false;

  static void initialize() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  static tz.Location? getLocation(String timezone) {
    initialize();
    try {
      return tz.getLocation(timezone);
    } catch (e) {
      print('Error getting location for timezone $timezone: $e');
      return null;
    }
  }

  static Future<String> getTime(String timezone) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${dotenv.env['TIME_API_BASE_URL']}/time/current/zone?timeZone=$timezone',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['time'];
      }
      throw Exception('Failed to load time');
    } catch (e) {
      throw Exception('Error getting time: $e');
    }
  }

  static DateTime convertTime(
    DateTime dateTime, {
    required String fromTimezone,
    required String toTimezone,
  }) {
    initialize();

    final fromLocation = tz.getLocation(fromTimezone);
    final toLocation = tz.getLocation(toTimezone);

    final fromTZDateTime = tz.TZDateTime(
      fromLocation,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    final toTZDateTime = tz.TZDateTime.from(fromTZDateTime, toLocation);

    return DateTime(
      toTZDateTime.year,
      toTZDateTime.month,
      toTZDateTime.day,
      toTZDateTime.hour,
      toTZDateTime.minute,
      toTZDateTime.second,
    );
  }

  static Future<Map<String, String>> getMultipleTimes(
    List<String> timezones,
  ) async {
    final Map<String, String> results = {};
    final List<String> timezonesToFetch = [];

    // Check cache first
    for (final timezone in timezones) {
      final cached = _cache[timezone];
      if (cached != null && !cached.isExpired) {
        results[timezone] = '${cached.time} $timezone';
      } else {
        timezonesToFetch.add(timezone);
      }
    }

    // Fetch uncached timezones in parallel
    if (timezonesToFetch.isNotEmpty) {
      final futures = timezonesToFetch.map((timezone) async {
        try {
          final time = await getTime(timezone);
          results[timezone] = time;
        } catch (e) {
          results[timezone] = 'Error loading time';
        }
      });

      await Future.wait(futures);
    }

    return results;
  }

  static void clearCache() {
    _cache.clear();
  }
}

class _CachedTime {
  final String time;
  final DateTime timestamp;

  _CachedTime(this.time) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > TimeService._cacheExpiration;
}
