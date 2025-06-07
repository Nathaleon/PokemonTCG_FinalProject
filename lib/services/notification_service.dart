import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const int COMPASS_NOTIFICATION_ID = 1001;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request permission on initialization
    await requestPermission();
  }

  Future<bool> requestPermission() async {
    final platform =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (platform != null) {
      // For Android 13 and above
      final granted = await platform.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> showFavoriteNotification(String cardName) async {
    const androidDetails = AndroidNotificationDetails(
      'favorites_channel',
      'Favorites',
      channelDescription: 'Notifications for favorite cards',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Kartu Favorit',
      'Kartu $cardName berhasil ditambahkan ke favorit',
      details,
    );
  }

  Future<void> showCompassNotification({required bool isEnabled}) async {
    if (isEnabled) {
      await _notifications.show(
        COMPASS_NOTIFICATION_ID,
        'Compass Active',
        'Tap to return to the app',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'compass_channel',
            'Compass',
            channelDescription: 'Notifications for compass feature',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            playSound: false,
            enableVibration: false,
            category: AndroidNotificationCategory.service,
            actions: [
              const AndroidNotificationAction(
                'stop_compass',
                'Stop Compass',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } else {
      await _notifications.cancel(COMPASS_NOTIFICATION_ID);
    }
  }
}
