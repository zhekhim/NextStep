import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../models/skill_task.dart';

class CalendarPermissionDeniedException implements Exception {
  const CalendarPermissionDeniedException();
}

class NoWritableCalendarException implements Exception {
  const NoWritableCalendarException();
}

class CalendarDestination {
  const CalendarDestination({
    required this.id,
    required this.name,
    required this.accountName,
    required this.accountType,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String? accountName;
  final String? accountType;
  final bool isPrimary;
}

class CalendarService {
  CalendarService({DeviceCalendar? calendar})
    : _calendar = calendar ?? DeviceCalendar.instance;

  final DeviceCalendar _calendar;
  Future<String> addMilestone({
    required SkillTask milestone,
    required String careerGoalTitle,
    required CalendarDestination destination,
  }) async {
    final startDate = DateTime(
      milestone.dueDate.year,
      milestone.dueDate.month,
      milestone.dueDate.day,
    );
    final eventId = await _calendar.createEvent(
      calendarId: destination.id,
      title: 'Career Goal - ${milestone.taskTitle}',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 1)),
      isAllDay: true,
      description: 'Milestone for "$careerGoalTitle"',
    );
    return eventId;
  }

  Future<void> openMilestoneEditor({
    required SkillTask milestone,
    required String careerGoalTitle,
  }) async {
    final permission = await _calendar.requestPermissions();
    if (permission != CalendarPermissionStatus.granted) {
      throw const CalendarPermissionDeniedException();
    }

    final startDate = DateTime(
      milestone.dueDate.year,
      milestone.dueDate.month,
      milestone.dueDate.day,
    );
    await _calendar.showCreateEventModal(
      title: 'Career Goal - ${milestone.taskTitle}',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 1)),
      isAllDay: true,
      description: 'Milestone for "$careerGoalTitle"',
    );
  }

  Future<void> updateMilestone({
    required String eventId,
    required String milestoneTitle,
    required DateTime dueDate,
    required String careerGoalTitle,
  }) async {
    final startDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    await _calendar.updateEvent(
      eventId: eventId,
      title: 'Career Goal - $milestoneTitle',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 1)),
      isAllDay: true,
      description: Patch.set('Milestone for "$careerGoalTitle"'),
    );
  }

  Future<void> removeEvent(String eventId) =>
      _calendar.deleteEvent(eventId: eventId);

  Future<List<CalendarDestination>> writableCalendars() async {
    final permission = await _calendar.requestPermissions();
    if (permission != CalendarPermissionStatus.granted) {
      throw const CalendarPermissionDeniedException();
    }
    final calendars = await _calendar.listCalendars();
    final writable = calendars
        .where((calendar) => !calendar.readOnly && !calendar.hidden)
        .toList();
    if (writable.isEmpty) throw const NoWritableCalendarException();
    writable.sort((a, b) {
      final aGoogle = a.accountType?.toLowerCase().contains('google') ?? false;
      final bGoogle = b.accountType?.toLowerCase().contains('google') ?? false;
      if (aGoogle != bGoogle) return aGoogle ? -1 : 1;
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return writable
        .map(
          (calendar) => CalendarDestination(
            id: calendar.id,
            name: calendar.name,
            accountName: calendar.accountName,
            accountType: calendar.accountType,
            isPrimary: calendar.isPrimary,
          ),
        )
        .toList();
  }
}
