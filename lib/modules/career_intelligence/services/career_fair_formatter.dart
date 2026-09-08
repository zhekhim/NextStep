import '../models/career_fair.dart';

class CareerFairFormatter {
  const CareerFairFormatter._();

  static String date(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  static String time(Duration value) {
    final hour = value.inHours % 24;
    final minute = value.inMinutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  static String timeRange(CareerFair fair) {
    final start = fair.startTime;
    if (start == null) return 'Time not specified';
    final end = fair.endTime;
    return end == null ? time(start) : '${time(start)} – ${time(end)}';
  }
}
