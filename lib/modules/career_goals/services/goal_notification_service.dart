import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationPermissionDeniedException implements Exception {
  const NotificationPermissionDeniedException();
}

class ReminderTimePassedException implements Exception {
  const ReminderTimePassedException();
}

class GoalNotificationService {
  GoalNotificationService._();

  static final GoalNotificationService instance = GoalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_nextstep'),
      ),
    );
    _initialized = true;
  }

  int notificationIdFor(String milestoneId) {
    final compact = milestoneId.replaceAll('-', '');
    return int.parse(compact.substring(0, 8), radix: 16) & 0x7fffffff;
  }

  DateTime reminderDate(DateTime dueDate, int daysBefore) => DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
    9,
  ).subtract(Duration(days: daysBefore));

  DateTime reminderUtc(DateTime dueDate, int daysBefore) {
    final malaysiaTime = reminderDate(dueDate, daysBefore);
    return DateTime.utc(
      malaysiaTime.year,
      malaysiaTime.month,
      malaysiaTime.day,
      malaysiaTime.hour,
    ).subtract(const Duration(hours: 8));
  }

  Future<void> schedule({
    required int notificationId,
    required String milestoneTitle,
    required DateTime dueDate,
    required int daysBefore,
  }) async {
    await initialize();
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) {
      throw const NotificationPermissionDeniedException();
    }

    final reminder = reminderDate(dueDate, daysBefore);
    if (!reminder.isAfter(DateTime.now())) {
      throw const ReminderTimePassedException();
    }

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Career Goal Reminder',
      body: _message(milestoneTitle, daysBefore),
      scheduledDate: tz.TZDateTime.from(
        reminderUtc(dueDate, daysBefore),
        tz.UTC,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'career_goal_deadlines',
          'Career goal deadlines',
          channelDescription: 'Reminders for development milestone deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_nextstep',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: milestoneTitle,
    );
  }

  Future<void> cancel(int notificationId) async {
    await initialize();
    await _notifications.cancel(id: notificationId);
  }

  String _message(String title, int daysBefore) {
    if (daysBefore == 0) return '$title is due today.';
    if (daysBefore == 1) return '$title is due tomorrow.';
    return '$title is due in $daysBefore days.';
  }
}
