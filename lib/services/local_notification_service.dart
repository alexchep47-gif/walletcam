import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (kIsWeb) return; // Notifications locales non supportées sur le web

    tz.initializeTimeZones();

    try {
      // flutter_timezone peut échouer sur certains environnements
      tz.setLocalLocation(tz.getLocation('Africa/Douala'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Africa/Douala'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Payload = ardoiseId
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleArdoiseReminder({
    required int notificationId,
    required String ardoiseId,
    required String clientName,
    required double amount,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'walletcam_treasury_reminders',
      'Relances de Dettes',
      channelDescription: 'Notifications pour le suivi des crédits clients',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    final scheduled = tz.TZDateTime.from(dueDate, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      notificationId,
      'Rappel de dette : $clientName',
      'Le crédit de ${amount.toStringAsFixed(0)} FCFA arrive à échéance aujourd\'hui.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: ardoiseId,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    if (kIsWeb) return;
    await _plugin.cancel(notificationId);
  }
}
