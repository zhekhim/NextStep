import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_goals/services/goal_notification_service.dart';

void main() {
  final service = GoalNotificationService.instance;

  test('notification ID is stable and remains a positive 32-bit integer', () {
    const milestoneId = '12345678-1234-1234-1234-123456789abc';

    final first = service.notificationIdFor(milestoneId);
    final second = service.notificationIdFor(milestoneId);

    expect(first, second);
    expect(first, inInclusiveRange(0, 0x7fffffff));
  });

  test('reminder date uses 9 AM and subtracts the selected number of days', () {
    final reminder = service.reminderDate(DateTime(2026, 10, 20), 3);

    expect(reminder, DateTime(2026, 10, 17, 9));
  });

  test('reminder converts Malaysia time to UTC without a timezone lookup', () {
    final reminder = service.reminderUtc(DateTime(2026, 10, 20), 3);

    expect(reminder, DateTime.utc(2026, 10, 17, 1));
  });
}
