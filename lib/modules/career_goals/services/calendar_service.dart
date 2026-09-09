import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../models/skill_task.dart';

class CalendarPermissionDeniedException implements Exception {
  const CalendarPermissionDeniedException();
}

class CalendarService {
  CalendarService({DeviceCalendar? calendar})
    : _calendar = calendar ?? DeviceCalendar.instance;

  final DeviceCalendar _calendar;

  Future<String> addMilestone({
    required SkillTask milestone,
    required String careerGoalTitle,
  }) async {
    final permission = await _calendar.requestPermissions(
      level: CalendarAccessLevel.writeOnly,
    );
    if (permission != CalendarPermissionStatus.granted &&
        permission != CalendarPermissionStatus.writeOnly) {
      throw const CalendarPermissionDeniedException();
    }

    final startDate = DateTime(
      milestone.dueDate.year,
      milestone.dueDate.month,
      milestone.dueDate.day,
    );
    return _calendar.createEvent(
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
}
