/// Open/close window helpers matching backend `checkGameTimeWindow` (IST).
class GameSchedule {
  const GameSchedule({
    required this.openTime,
    required this.closeTime,
  });

  final String openTime;
  final String closeTime;

  static DateTime nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  static int? hmToMinutes(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String formatClockLabel(String hm) {
    final minutes = hmToMinutes(hm);
    if (minutes == null) return hm;
    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  int? get openMinutes => hmToMinutes(openTime);
  int? get closeMinutes => hmToMinutes(closeTime);

  bool get hasTimes => openMinutes != null && closeMinutes != null;

  bool get isClosed {
    final open = openMinutes;
    final close = closeMinutes;
    if (open == null || close == null) return false;

    final now = nowIst();
    final current = now.hour * 60 + now.minute;

    if (close < open) {
      return current >= close && current < open;
    }
    return current >= close || current < open;
  }

  String get opensAtLabel {
    final open = openTime.trim();
    if (open.isEmpty) return 'Opens at --';
    return 'Opens at ${formatClockLabel(open)}';
  }

  Duration? get timeUntilClose {
    if (isClosed) return null;
    final open = openMinutes;
    final close = closeMinutes;
    if (open == null || close == null) return null;

    final now = nowIst();
    final current = now.hour * 60 + now.minute;
    final nowFloor = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );

    DateTime closeAt;
    if (close < open) {
      if (current < close) {
        closeAt = DateTime(now.year, now.month, now.day)
            .add(Duration(minutes: close));
      } else {
        closeAt = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1))
            .add(Duration(minutes: close));
      }
    } else {
      closeAt = DateTime(now.year, now.month, now.day)
          .add(Duration(minutes: close));
    }

    return closeAt.difference(nowFloor);
  }

  String? get closeCountdownLabel {
    final remaining = timeUntilClose;
    if (remaining == null) return null;
    final seconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  DateTime? get closedSessionResultDate {
    if (!isClosed) return null;
    final open = openMinutes;
    final close = closeMinutes;
    if (open == null || close == null) return null;

    final now = nowIst();
    final today = DateTime(now.year, now.month, now.day);
    final current = now.hour * 60 + now.minute;

    if (close < open) {
      return today;
    }
    if (current >= close) return today;
    return today.subtract(const Duration(days: 1));
  }
}
