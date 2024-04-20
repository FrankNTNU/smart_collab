import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

// a static class
class TimeUtils {
  static String getFuzzyTime(DateTime time, {int onlyFuzzyDaysBefore = 3, BuildContext? context}) {
    
    final daysAgo = DateTime.now().difference(time).inDays;
    final locale = '${context?.locale.languageCode}_${context?.locale.countryCode}';
    final createdAtMessage =
        daysAgo > onlyFuzzyDaysBefore ? time.toString() : timeago.format(time, locale: locale);
    return createdAtMessage;
  }
}