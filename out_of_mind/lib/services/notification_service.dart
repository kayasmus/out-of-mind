import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';


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

static Future<void> scheduleWeeklyReflection(int weekday, TimeOfDay time) async {
  final now = tz.TZDateTime.now(tz.UTC);
  var scheduled = tz.TZDateTime(tz.UTC, now.year, now.month, now.day, time.hour, time.minute);

  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    998,
    'Out of Mind',
    'Time to reflect on last week\'s spending 🧠',
    scheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_reflection',
        'Weekly Reflection Reminder',
        channelDescription: 'Weekly reminder to check your spending reflection',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexact,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

static Future<void> cancelWeeklyReflection() async {
  await _plugin.cancel(998);
}
}
