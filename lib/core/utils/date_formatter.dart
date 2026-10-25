import 'package:intl/intl.dart';

/// Humanized, clear relative and absolute date formatting for notes.
class DateFormatter {
  DateFormatter._();

  static DateTime parse(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Compact smart label: "Just now", "12m ago", "Today, 4:12 PM", "Yesterday", "Oct 14"
  static String formatSmart(dynamic date) {
    final dt = parse(date);
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60 && difference.inSeconds >= 0) {
      return 'Just now';
    }

    if (difference.inMinutes < 60 && difference.inMinutes >= 0) {
      return '${difference.inMinutes}m ago';
    }

    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return DateFormat('h:mm a').format(dt);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isYesterday) {
      return 'Yesterday';
    }

    if (dt.year == now.year) {
      return DateFormat('MMM d').format(dt);
    }

    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Detailed timestamp: "October 22, 2026 • 3:30 PM"
  static String formatFull(dynamic date) {
    final dt = parse(date);
    return DateFormat('MMMM d, y • h:mm a').format(dt);
  }
}
