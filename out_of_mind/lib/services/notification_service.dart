import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Reserved IDs for app-level notifications. Planned-purchase reminders use
  // their DB row id + _reminderIdOffset so they can never collide with these.
  static const int weeklyReflectionId = 1;
  static const int weeklyInsightId = 2;
  static const int _reminderIdOffset = 1000;

static Future<void> initialize() async {
  tz_data.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (_) {
    // Fall back to UTC if the device timezone can't be resolved.
    tz.setLocalLocation(tz.UTC);
  }

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

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
      _reminderIdOffset + id,
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
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(_reminderIdOffset + id);
  }

  static Future<void> sendWeeklyInsight(String mood, String message) async {
  await _plugin.show(
    weeklyInsightId,
    'Out of Mind — Weekly Insight',
    message,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_insight',
        'Weekly Spending Insights',
        channelDescription: 'Weekly mood and spending pattern notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

static Future<void> scheduleWeeklyReflection(int weekday, TimeOfDay time) async {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    weeklyReflectionId,
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
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

static Future<void> cancelWeeklyReflection() async {
  await _plugin.cancel(weeklyReflectionId);
}
}
