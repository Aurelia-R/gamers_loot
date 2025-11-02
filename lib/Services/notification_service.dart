import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Inisialisasi notification service
  static Future<void> initialize() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap jika diperlukan
      },
    );

    // Request permission untuk Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // Tampilkan notifikasi sederhana
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Buat channel untuk Android (harus dibuat sebelum show notification)
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ticket_channel',
          'Event Tickets',
          description: 'Notifications untuk tiket event',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'ticket_channel',
      'Event Tickets',
      channelDescription: 'Notifications untuk tiket event',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Notification details
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(id, title, body, details);
  }

  // Notifikasi khusus untuk tiket berhasil di-claim
  static Future<void> showTicketClaimedNotification(String eventName) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Tiket Berhasil Di-claim! 🎉',
      body: 'Tiket untuk "$eventName" berhasil di-claim! Lihat QR code di Profile > My Tickets',
    );
  }
}

