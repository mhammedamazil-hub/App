/// Locale-free date helpers used across TaskFlow.
const List<String> monthNames = [
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

const List<String> weekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

int daysUntil(DateTime from, DateTime to) =>
    startOfDay(to).difference(startOfDay(from)).inDays;

/// Whole days between the two dates (negative if [a] is after [b]).
int dayDiff(DateTime a, DateTime b) =>
    startOfDay(b).difference(startOfDay(a)).inDays;

String two(int n) => n.toString().padLeft(2, '0');

/// 12-hour time, e.g. `9:05 AM` / `11:30 PM`.
String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  return '$h:${two(t.minute)} $suffix';
}

/// `Aug 16` (adds year when it differs from the current one).
String fmtDate(DateTime t, {bool withYear = false}) {
  final base = '${monthNames[t.month - 1]} ${t.day}';
  return withYear ? '$base, ${t.year}' : base;
}

String fmtDateFull(DateTime t) =>
    '${monthNames[t.month - 1]} ${t.day}, ${t.year}';

String weekdayOf(DateTime t) => weekdayNames[t.weekday - 1];

/// Human-friendly relative date: Today / Tomorrow / Yesterday / weekday /
/// "Aug 14" / "Aug 14, 2025".
String smartDate(DateTime t, DateTime now) {
  final diff = dayDiff(now, t);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff < -1 && diff >= -6) return 'Last ${weekdayOf(t)}';
  if (diff > 1 && diff <= 6) return weekdayOf(t);
  return fmtDate(t, withYear: t.year != now.year);
}

/// Short label for a due date, relative to now: `Today`, `Tomorrow`,
/// `In 3 days`, `2 days overdue`, `Aug 14`, `Aug 14, 2025`.
String dueLabel(DateTime due, DateTime now) {
  final diff = dayDiff(now, due);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff <= 7) return 'In $diff days';
  if (diff < -1 && diff >= -7) return '${-diff} days overdue';
  if (diff < -7) return '${-diff}d overdue';
  return fmtDate(due, withYear: due.year != now.year);
}

/// True when the time part is midnight (i.e. a date-only deadline).
bool isAllDay(DateTime d) => d.hour == 23 && d.minute == 59;

/// Timestamp used in backup file names: `20260816-140530`.
String fileStamp(DateTime t) =>
    '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
