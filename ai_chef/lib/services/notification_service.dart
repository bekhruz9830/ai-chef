import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

const _prefKey = 'notifications_enabled';
const _dailyHour = 9;
const _dailyMinute = 0;
const _channelId = 'ai_chef_daily';
const _channelName = 'Daily reminders';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _enabled = false;
  bool get enabled => _enabled;

  static const int _dailyId = 1;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelect,
    );
    await _createChannel();
    await _loadEnabled();
  }

  void _onSelect(NotificationResponse response) {}

  Future<void> _createChannel() async {
    final android = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily cooking reminders from AI Chef',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(android);
  }

  Future<void> _loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (value) {
      await _scheduleDaily();
    } else {
      await _cancelAll();
    }
    notifyListeners();
  }

  Future<void> _scheduleDaily() async {
    await _cancelAll();
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily cooking reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    await _plugin.zonedSchedule(
      _dailyId,
      'AI Chef 👨‍🍳',
      'Time to cook something delicious! Open AI Chef for recipe ideas.',
      _nextDailyTime(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextDailyTime() {
    final now = tz.TZDateTime.now(tz.UTC);
    var scheduled = tz.TZDateTime(tz.UTC, now.year, now.month, now.day, _dailyHour, _dailyMinute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _cancelAll() async {
    await _plugin.cancel(_dailyId);
    await _plugin.cancelAll();
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok = await ios.requestPermissions(alert: true, badge: true);
      return ok ?? true;
    }
    return true;
  }
}