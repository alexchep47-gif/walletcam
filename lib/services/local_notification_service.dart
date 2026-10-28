import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback Cameroun
      tz.setLocalLocation(tz.getLocation('Africa/Douala'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Payload = ardoiseId — peut être utilisé pour la navigation
      },
    );

    // Permission Android 13+
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

    // Ne pas planifier si déjà passé
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
    await _plugin.cancel(notificationId);
  }
}
