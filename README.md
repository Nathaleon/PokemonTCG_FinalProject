# PokemonTCG App

A Flutter application for Pokemon Trading Card Game enthusiasts. This app allows users to browse Pokemon cards, register for tournaments, and manage their profiles.

## Features

- Browse and search Pokemon cards
- View detailed card information
- Register for tournaments with location-based services
- Profile management
- Course feedback system
- Time zone conversion for tournaments

## Setup Instructions

1. Clone the repository
```bash
git clone https://github.com/yourusername/pokemontcg.git
cd pokemontcg
```

2. Create a `.env` file in the root directory with the following content:
```
POKEMON_TCG_API_KEY=your_api_key_here
POKEMON_TCG_BASE_URL=https://api.pokemontcg.io/v2
TIME_API_BASE_URL=https://timeapi.io/api
```

3. Get your Pokemon TCG API key from [Pokemon TCG Developer Portal](https://dev.pokemontcg.io/)

4. Install dependencies
```bash
flutter pub get
```

5. Run the app
```bash
flutter run
```

## Dependencies

- Flutter SDK: ^3.7.0
- Provider: ^6.1.1
- HTTP: ^1.1.0
- Google Maps Flutter: ^2.5.3
- Shared Preferences: ^2.2.2
- And more (see pubspec.yaml)

## Project Structure

```
lib/
  ├── main.dart
  ├── providers/
  │   ├── auth_provider.dart
  │   └── pokemon_provider.dart
  ├── screens/
  │   ├── splash_screen.dart
  │   ├── login_screen.dart
  │   ├── register_screen.dart
  │   ├── home_screen.dart
  │   ├── pokecard_screen.dart
  │   ├── card_detail_screen.dart
  │   ├── tournament_screen.dart
  │   ├── tournament_registration_screen.dart
  │   └── profile_screen.dart
  └── widgets/
      └── (shared widgets)
```

## Features to Add

- [ ] Currency conversion for card prices
- [ ] More tournament locations
- [ ] User card collection management
- [ ] Trading system
- [ ] Push notifications for tournament updates

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
