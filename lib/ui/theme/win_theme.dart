import 'package:flutter/material.dart';

class WinTheme {
  static const Color bg = Color(0xFF0B141A);
  static const Color surface = Color(0xFF141414);
  static const Color card = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF2A2A2A);
  static const Color green = Color(0xFF22C55E);
  static const Color greenSoft = Color(0xFF16351F);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color gold = Color(0xFFEAB308);
  static const Color blue = Color(0xFF60A5FA);
  static const Color yellow = Color(0xFFFACC15);

  static String rupee(num value) {
    final n = value.toDouble();
    if (n.truncateToDouble() == n) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  static String lskLabel(String lsk) {
    switch (lsk.toUpperCase()) {
      case 'DEAR':
        return 'SUPER';
      case 'BOX':
        return 'BOX';
      default:
        return lsk.toUpperCase();
    }
  }

  static String drawLabel(String timeSlot) {
    switch (timeSlot) {
      case '1pm':
        return 'Draw 1 PM';
      case '2pm':
        return 'Draw 2 PM';
      case '3pm':
        return 'Draw 3 PM';
      case '6pm':
        return 'Draw 6 PM';
      case '8pm':
        return 'Draw 8 PM';
      default:
        return timeSlot;
    }
  }

  static String weekdayCommaDate(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
    final label =
        '${weekdays[local.weekday - 1]}, ${local.day} ${months[local.month - 1]}';
    if (local.year != DateTime.now().year) {
      return '$label ${local.year}';
    }
    return label;
  }

  static String monthDay(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  static DateTime? calendarDay(DateTime? d) {
    if (d == null) return null;
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool sameDay(DateTime? a, DateTime? b) {
    final da = calendarDay(a);
    final db = calendarDay(b);
    if (da == null || db == null) return false;
    return da == db;
  }

  static String dayChip(DateTime? d) {
    final day = calendarDay(d);
    if (day == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
    return monthDay(day);
  }
}
