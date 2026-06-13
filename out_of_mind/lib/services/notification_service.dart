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
  static const int locationAlertId = 3;
  static const int _reminderIdOffset = 1000;

  // Payload values used to route the user when they tap a notification.
  static const String payloadPlanned = 'planned';
  static const String payloadReflection = 'reflection';
  static const String payloadInsight = 'insight';

static Future<void> initialize(
    {void Function(String? payload)? onTap}) async {
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

  await _plugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) =>
        onTap?.call(response.payload),
  );

  await _plugin
      .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

  /// Payload of the notification that launched the app (cold start), if any.
  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  static Future<void> scheduleReminder(
      int id, String itemName, DateTime date, TimeOfDay time) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
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
      payload: payloadPlanned,
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
    payload: payloadInsight,
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
      // New channel id (v2): the original channel was created at default
      // importance and Android won't upgrade an existing channel in place.
      android: AndroidNotificationDetails(
        'weekly_reflection_v2',
        'Weekly Reflection Reminder',
        channelDescription: 'Weekly reminder to check your spending reflection',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: payloadReflection,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

static Future<void> cancelWeeklyReflection() async {
  await _plugin.cancel(weeklyReflectionId);
}

  /// Fired when the user enters a tracked location.
  /// Tapping the notification opens the Planned screen.
  static Future<void> showLocationAlert(String locationName) async {
    await _plugin.show(
      locationAlertId,
      'Impulse check 🧠',
      "You're near $locationName — feeling an urge to buy something?",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'location_alerts',
          'Location Alerts',
          channelDescription:
              'Alerts when you enter tracked spending locations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payloadPlanned,
    );
  }
}
