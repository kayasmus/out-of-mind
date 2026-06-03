import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;


class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

static Future<void> initialize() async {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.UTC);

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await _plugin.initialize(initSettings);

  await _plugin
      .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

  static Future<void> scheduleReminder(
      int id, String itemName, DateTime date) async {
    final scheduledDate = tz.TZDateTime(
  tz.local,
  date.year,
  date.month,
  date.day,
  9,
  0,
);

    await _plugin.zonedSchedule(
      id,
      'Out of Mind',
      'Still thinking about $itemName?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'planned_reminders',
          'Planned Purchase Reminders',
          channelDescription: 'Reminders for your planned purchases',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> sendWeeklyInsight(String mood, String emoji) async {
  await _plugin.show(
    999,
    'Out of Mind — Weekly Insight',
    'You tend to spend most when feeling $mood $emoji. Stay mindful this week.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_insight',
        'Weekly Spending Insights',
        channelDescription: 'Weekly mood and spending pattern notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
  );
}
}
