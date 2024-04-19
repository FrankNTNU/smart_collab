import 'package:timeago/timeago.dart' as timeago;

// a static class
class TimeUtils {
  static String getFuzzyTime(DateTime time, {int onlyFuzzyDaysBefore = 3}) {
    final daysAgo = DateTime.now().difference(time).inDays;
    final createdAtMessage =
        daysAgo > onlyFuzzyDaysBefore ? time.toString() : timeago.format(time);
    return createdAtMessage;
  }
}