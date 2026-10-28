const _months = [
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

/// `12:34 PM` in the phone's time zone.
String formatClock(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

/// `12:34 PM` for today, otherwise `Oct 21`.
String formatClockOrDate(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay
      ? formatClock(local)
      : '${_months[local.month - 1]} ${local.day}';
}

/// Elapsed time as the device list shows it: `0min`, `1min`, `18mins`.
String formatMinutes(int minutes) => '${minutes}min${minutes > 1 ? 's' : ''}';
