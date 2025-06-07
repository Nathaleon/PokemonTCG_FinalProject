import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import '../data/tournament_locations.dart';
import '../services/time_service.dart';
import '../services/notification_service.dart';
import 'tournament_registration_screen.dart';

class TournamentScreen extends StatefulWidget {
  final TournamentLocation? initialLocation;

  const TournamentScreen({super.key, this.initialLocation});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final NotificationService _notificationService = NotificationService();
  TournamentLocation? _selectedLocation;
  String _currentTime = '';
  bool _isLoading = false;
  bool _disposed = false;
  bool _compassEnabled = false;
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0;
  double _lastKnownRotation = 0.0;
  bool _isRotating = false;
  final List<double> _headingValues = [];
  static const int _smoothingSamples = 5;
  bool _hasCompass = false;
  bool _isCurrentRoute = true;
  Timer? _smoothRotationTimer;
  double _targetRotation = 0.0;
  double _currentMapRotation = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCompassAvailability();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _loadLocationTime(widget.initialLocation!);
    }
    // Initialize map rotation to 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.rotate(0);
      }
    });
  }

  @override
  void dispose() {
    if (!_isCurrentRoute) {
      _stopCompass();
    }
    _disposed = true;
    _smoothRotationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.detached) {
      // Only stop compass when app is fully closed
      _stopCompass();
    } else if (state == AppLifecycleState.resumed && _compassEnabled) {
      // Resume compass if it was enabled
      _startCompass();
    }
    // Do nothing for paused and inactive states to keep compass running
  }

  Future<void> _checkCompassAvailability() async {
    if (!mounted) return;

    try {
      _hasCompass =
          await FlutterCompass.events?.first
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout:
                    () => throw TimeoutException('Compass not available'),
              )
              .then((_) => true) ??
          false;
    } catch (e) {
      debugPrint('Compass not available: $e');
      _hasCompass = false;
    }

    if (mounted) setState(() {});
  }

  void _toggleCompass() async {
    if (!mounted) return;

    // Request notification permission before showing compass notification
    await _notificationService.requestPermission();

    setState(() {
      _compassEnabled = !_compassEnabled;
    });

    if (_compassEnabled) {
      _startCompass();
      await _notificationService.showCompassNotification(isEnabled: true);
    } else {
      _stopCompass();
      await _notificationService.showCompassNotification(isEnabled: false);
    }
  }

  void _startCompass() {
    if (!_hasCompass) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compass tidak tersedia pada perangkat ini'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _compassEnabled = true;
    });

    // Reset rotasi
    _targetRotation = 0.0;
    _currentMapRotation = 0.0;

    // Mulai compass subscription
    _compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (!mounted || !_compassEnabled) return;

        final double? heading = event.heading;
        if (heading != null && !heading.isNaN && heading.isFinite) {
          _updateHeading(heading);
        }
      },
      onError: (error) {
        debugPrint('Compass error: $error');
        if (mounted) {
          _stopCompass();
        }
      },
    );

    // Mulai smooth rotation timer
    _startSmoothRotation();
  }

  void _startSmoothRotation() {
    _smoothRotationTimer?.cancel();
    _smoothRotationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // 60 FPS untuk rotasi lebih halus
      (timer) {
        if (!mounted || !_compassEnabled) {
          timer.cancel();
          return;
        }
        _applySmoothRotation();
      },
    );
  }

  void _updateHeading(double newHeading) {
    if (!mounted || !_compassEnabled) return;

    // Normalisasi heading ke 0-360
    newHeading = (newHeading + 360) % 360;

    setState(() {
      _currentHeading = newHeading;
      // Set target rotasi (negatif untuk rotasi searah jarum jam)
      _targetRotation = -newHeading * (math.pi / 180);
    });
  }

  void _applySmoothRotation() {
    if (!mounted || !_compassEnabled) return;

    try {
      // Hitung perbedaan antara rotasi saat ini dan target
      double diff = _targetRotation - _currentMapRotation;

      // Normalisasi perbedaan ke jalur terpendek [-π, π]
      while (diff > math.pi) diff -= 2 * math.pi;
      while (diff < -math.pi) diff += 2 * math.pi;

      // Terapkan interpolasi halus dengan faktor yang lebih responsif
      const double lerpFactor = 0.15; // Faktor kelancaran yang lebih tinggi

      // Hanya rotate jika perbedaannya signifikan
      if (diff.abs() > 0.001) {
        // Threshold yang lebih kecil untuk responsivitas lebih baik
        final double newRotation = _currentMapRotation + (diff * lerpFactor);

        // Update rotasi peta
        _mapController.rotate(newRotation);
        _currentMapRotation = newRotation;
      }
    } catch (e) {
      debugPrint('Error applying rotation: $e');
    }
  }

  void _stopCompass() {
    _compassSubscription?.cancel();
    _smoothRotationTimer?.cancel();

    if (mounted) {
      setState(() {
        _compassEnabled = false;
        _currentHeading = 0;
      });

      // Reset rotasi peta ke north (0 derajat)
      try {
        _mapController.rotate(0);
        _currentMapRotation = 0.0;
        _targetRotation = 0.0;
      } catch (e) {
        debugPrint('Error resetting map rotation: $e');
      }
    }
  }

  Future<void> _loadLocationTime(TournamentLocation location) async {
    if (_disposed) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final time = await TimeService.getTime(location.timezone);

      if (_disposed) return;

      if (!mounted) return;
      setState(() {
        _currentTime = time;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentTime = 'Error loading time';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLocationDetails(TournamentLocation location) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
    });
    _loadLocationTime(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon TCG Tournaments'),
        actions: [
          if (_hasCompass)
            IconButton(
              icon: Icon(
                _compassEnabled ? Icons.explore : Icons.explore_outlined,
              ),
              onPressed: _toggleCompass,
              tooltip: _compassEnabled ? 'Disable Compass' : 'Enable Compass',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        widget.initialLocation?.coordinates ??
                        const LatLng(20.0, 105.0),
                    initialZoom: widget.initialLocation != null ? 15.0 : 3.0,
                    onMapReady: () {
                      if (widget.initialLocation != null) {
                        _mapController.move(
                          widget.initialLocation!.coordinates,
                          15.0,
                        );
                      }
                    },
                    keepAlive: true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pokemontcg.app',
                    ),
                    MarkerLayer(
                      markers:
                          tournamentLocations.map((location) {
                            return Marker(
                              point: location.coordinates,
                              child: GestureDetector(
                                onTap: () => _showLocationDetails(location),
                                child: Icon(
                                  Icons.location_on,
                                  color:
                                      _selectedLocation == location
                                          ? Colors.red
                                          : Colors.blue,
                                  size: 40,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                if (_compassEnabled)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: _currentHeading * (math.pi / 180),
                            child: const Icon(Icons.navigation),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentHeading.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tournament Details Section
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedLocation!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedLocation!.city}, ${_selectedLocation!.country}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Venue: ${_selectedLocation!.venue}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLocation!.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            'Current Time: $_currentTime',
                            style: const TextStyle(fontSize: 14),
                          ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tournament Date: ${DateFormat('EEEE, d MMMM y - HH:mm').format(_selectedLocation!.tournamentDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TournamentRegistrationScreen(
                                  tournament: {
                                    'name': _selectedLocation!.name,
                                    'location':
                                        '${_selectedLocation!.city}, ${_selectedLocation!.country}',
                                    'venue': _selectedLocation!.venue,
                                    'date':
                                        _selectedLocation!.tournamentDate
                                            .toString(),
                                  },
                                ),
                          ),
                        );
                      },
                      child: const Text('Register for Tournament'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
