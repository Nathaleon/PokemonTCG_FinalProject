import 'package:latlong2/latlong.dart';

class TournamentLocation {
  final String name;
  final String city;
  final String country;
  final LatLng coordinates;
  final String timezone;
  final String description;
  final DateTime tournamentDate;
  final String venue;

  TournamentLocation({
    required this.name,
    required this.city,
    required this.country,
    required this.coordinates,
    required this.timezone,
    required this.description,
    required this.tournamentDate,
    required this.venue,
  });
}

final List<TournamentLocation> tournamentLocations = [
  // Japan
  TournamentLocation(
    name: 'Tokyo Pokemon Championship',
    city: 'Tokyo',
    country: 'Japan',
    coordinates: LatLng(35.7056, 139.7518),
    timezone: 'Asia/Tokyo',
    description: 'Annual Pokemon TCG Championship in Tokyo',
    tournamentDate: DateTime(2025, 8, 15, 10, 0),
    venue: 'Tokyo Dome',
  ),

  // USA
  TournamentLocation(
    name: 'US National Championship',
    city: 'New York',
    country: 'USA',
    coordinates: LatLng(40.7128, -74.0060),
    timezone: 'America/New_York',
    description: 'US National Pokemon TCG Tournament',
    tournamentDate: DateTime(2025, 8, 28, 9, 0), // 28 Agustus 2025, 09:00
    venue: '',
  ),

  // UK
  TournamentLocation(
    name: 'British Pokemon League',
    city: 'London',
    country: 'UK',
    coordinates: LatLng(51.5225, -0.1508),
    timezone: 'Europe/London',
    description: 'Official British Pokemon TCG League Tournament',
    tournamentDate: DateTime(2025, 9, 5, 11, 0),
    venue: 'St Mary Marylebone',
  ),

  // India
  TournamentLocation(
    name: 'India Pokemon Championship',
    city: 'Noida',
    country: 'India',
    coordinates: LatLng(28.5355, 77.3910),
    timezone: 'Asia/Kolkata',
    description: 'National Pokemon TCG Championship of India',
    tournamentDate: DateTime(2025, 9, 12, 10, 30),
    venue: 'The Great India Place',
  ),

  // Korea
  TournamentLocation(
    name: 'Korea Pokemon Masters',
    city: 'Seoul',
    country: 'South Korea',
    coordinates: LatLng(37.5108, 127.0590),
    timezone: 'Asia/Seoul',
    description: 'Korean Pokemon TCG Championship',
    tournamentDate: DateTime(2025, 9, 20, 10, 0),
    venue: 'Starfield COEX Mall',
  ),

  // Indonesia (WIB)
  TournamentLocation(
    name: 'Jakarta Pokemon Tournament',
    city: 'Jakarta',
    country: 'Indonesia',
    coordinates: LatLng(-6.1944, 106.8197),
    timezone: 'Asia/Jakarta',
    description: 'Jakarta Regional Pokemon TCG Tournament',
    tournamentDate: DateTime(2025, 10, 5, 10, 0),
    venue: 'Grand Indonesia',
  ),

  // Indonesia (WITA)
  TournamentLocation(
    name: 'Makassar Pokemon Cup',
    city: 'Makassar',
    country: 'Indonesia',
    coordinates: LatLng(-5.1477, 119.4327),
    timezone: 'Asia/Makassar',
    description: 'Makassar Regional Pokemon TCG Tournament',
    tournamentDate: DateTime(2025, 10, 12, 10, 0),
    venue: 'Trans Studio Makassar',
  ),

  // Indonesia (WIT)
  TournamentLocation(
    name: 'Jayapura Pokemon League',
    city: 'Jayapura',
    country: 'Indonesia',
    coordinates: LatLng(-2.5916, 140.6690),
    timezone: 'Asia/Jayapura',
    description: 'Jayapura Regional Pokemon TCG Tournament',
    tournamentDate: DateTime(2025, 10, 19, 10, 0),
    venue: 'Mall Jayapura',
  ),
];
