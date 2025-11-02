import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {

      },
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {

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

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  static Future<void> showTicketClaimedNotification(String eventName) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Tiket Berhasil Di-claim! 🎉',
      body: 'Tiket untuk "$eventName" berhasil di-claim! Lihat QR code di Profile > My Tickets',
    );
  }

  static Future<void> scheduleWishlistGameNotification({
    required int gameId,
    required String gameTitle,
    required DateTime scheduledDate,
  }) async {

    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'wishlist_channel',
          'Wishlist Reminder',
          description: 'Notifikasi untuk game di wishlist yang mau selesai',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'wishlist_channel',
      'Wishlist Reminder',
      channelDescription: 'Notifikasi untuk game di wishlist yang mau selesai',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      gameId,
      'Game Wishlist Mau Selesai! ⏰',
      'Game "$gameTitle" di wishlist kamu akan segera berakhir. Cepat claim sekarang!',
      _convertToTZDateTime(scheduledDate),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelWishlistNotification(int gameId) async {
    await _notifications.cancel(gameId);
  }

  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {

    return tz.TZDateTime.from(dateTime, tz.local);
  }
}

