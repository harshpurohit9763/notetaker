import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as android_specific_notifications;

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final android_specific_notifications.FlutterLocalNotificationsPlugin
      flutterLocalNotificationsPlugin =
      android_specific_notifications.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final android_specific_notifications.AndroidInitializationSettings
        initializationSettingsAndroid =
        android_specific_notifications.AndroidInitializationSettings(
            '@mipmap/ic_launcher');

    final android_specific_notifications.DarwinInitializationSettings
        initializationSettingsIOS =
        android_specific_notifications.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final android_specific_notifications.InitializationSettings
        initializationSettings =
        android_specific_notifications.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int priority,
    Color? color,
    String? sound, // Added sound parameter
  }) async {
    final tz.TZDateTime scheduledTZDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    final android_specific_notifications.AndroidNotificationDetails
        androidPlatformChannelSpecifics =
        android_specific_notifications.AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Channel for reminder notifications',
      importance: priority == 2
          ? android_specific_notifications.Importance.max
          : android_specific_notifications.Importance.defaultImportance,
      priority: priority == 2
          ? android_specific_notifications.Priority.high
          : android_specific_notifications.Priority.defaultPriority,
      color: color,
      fullScreenIntent: priority == 2,
      sound: sound != null
          ? android_specific_notifications.RawResourceAndroidNotificationSound(
              sound)
          : null, // Use the sound parameter
    );

    final android_specific_notifications.DarwinNotificationDetails
        iOSPlatformChannelSpecifics =
        android_specific_notifications.DarwinNotificationDetails(
      sound: sound, // Use the sound parameter for iOS as well
    );

    final android_specific_notifications.NotificationDetails
        platformChannelSpecifics =
        android_specific_notifications.NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    android_specific_notifications.AndroidScheduleMode androidScheduleMode =
        android_specific_notifications.AndroidScheduleMode.exactAllowWhileIdle;

    final android_specific_notifications.AndroidFlutterLocalNotificationsPlugin?
        androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            android_specific_notifications
            .AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Explicitly cast to the Android-specific plugin to access its methods
      final android_specific_notifications
          .AndroidFlutterLocalNotificationsPlugin androidPlugin =
          androidImplementation;
      bool canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        final bool? granted =
            await androidPlugin.requestExactAlarmsPermission();
        if (granted != true) {
          androidScheduleMode =
              android_specific_notifications.AndroidScheduleMode.alarmClock;
        }
      }
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        platformChannelSpecifics,
        androidScheduleMode: androidScheduleMode,
        // Removed uiLocalNotificationDateInterpretation as it's not for Android
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTZDate,
          platformChannelSpecifics,
          androidScheduleMode:
              android_specific_notifications.AndroidScheduleMode.alarmClock,
          // Removed uiLocalNotificationDateInterpretation as it's not for Android
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
