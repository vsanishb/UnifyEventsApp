import 'package:flutter/material.dart';
import '../../features/events/domain/models/booking_models.dart';

class EventDateTimeHelper {
  static DateTime? _parseDateTime(String? val) {
    if (val == null || val.isEmpty) return null;
    try {
      return DateTime.parse(val);
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> getEventDateTime({
    required String? serializerDate,
    required Map<String, dynamic>? details,
    required List<SlotModel>? slots,
  }) {
    DateTime? earliest;

    // 1. Check slots
    if (slots != null && slots.isNotEmpty) {
      for (var slot in slots) {
        if (slot.date.isEmpty) continue;
        String dtStr = slot.date;
        if (slot.startTime.isNotEmpty) {
          // Check if slot.startTime has a colon or space
          if (slot.startTime.contains(':')) {
            dtStr = "${slot.date} ${slot.startTime}";
          }
        }
        final parsed = _parseDateTime(dtStr) ?? _parseDateTime(slot.date);
        if (parsed != null) {
          if (earliest == null || parsed.isBefore(earliest)) {
            earliest = parsed;
          }
        }
      }
    }

    // 2. Check details
    if (earliest == null && details != null) {
      final startDt = details['start_datetime']?.toString() ?? details['date']?.toString();
      final parsed = _parseDateTime(startDt);
      if (parsed != null) {
        earliest = parsed;
      }
    }

    // 3. Check serializerDate
    if (earliest == null && serializerDate != null && serializerDate.isNotEmpty) {
      final parsed = _parseDateTime(serializerDate);
      if (parsed != null) {
        earliest = parsed;
      }
    }

    if (earliest != null) {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final dateStr = "${months[earliest.month - 1]} ${earliest.day}, ${earliest.year}";

      final hour = earliest.hour > 12 ? earliest.hour - 12 : (earliest.hour == 0 ? 12 : earliest.hour);
      final period = earliest.hour >= 12 ? "PM" : "AM";
      final minuteStr = earliest.minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');
      final timeStr = "$hourStr:$minuteStr $period";

      return {
        'date': dateStr,
        'time': timeStr,
      };
    }

    // Fallbacks if we can't parse as DateTime
    String dateFallback = "Date TBA";
    String timeFallback = "Time TBA";

    String? rawDateStr;
    if (details != null) {
      rawDateStr = details['start_datetime']?.toString() ?? details['date']?.toString() ?? details['start_time']?.toString();
    }
    rawDateStr ??= serializerDate;

    if (rawDateStr != null && rawDateStr.isNotEmpty) {
      if (rawDateStr.contains(' ')) {
        final parts = rawDateStr.split(' ');
        dateFallback = parts.first;
        timeFallback = parts.last;
      } else {
        dateFallback = rawDateStr;
      }
    }

    return {
      'date': dateFallback,
      'time': timeFallback,
    };
  }

  static bool isTimeOfDayBeforeOrEqual(TimeOfDay t1, TimeOfDay t2) {
    if (t1.hour < t2.hour) return true;
    if (t1.hour > t2.hour) return false;
    return t1.minute <= t2.minute;
  }

  static TimeOfDay? timeOfDayFromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}
    return null;
  }
  static bool passesDateTime({
    required String? serializerDate,
    required Map<String, dynamic>? details,
    required List<dynamic>? slots,
    required DateTime? filterDate,
    required TimeOfDay? filterStartTime,
    required TimeOfDay? filterEndTime,
  }) {
    if (filterDate == null && filterStartTime == null && filterEndTime == null) {
      return true;
    }

    // 1. Check if there are slots
    if (slots != null && slots.isNotEmpty) {
      for (var slot in slots) {
        // Date check
        if (filterDate != null) {
          final slotDateStr = slot.date?.toString() ?? "";
          final slotDt = DateTime.tryParse(slotDateStr);
          if (slotDt == null ||
              slotDt.year != filterDate.year ||
              slotDt.month != filterDate.month ||
              slotDt.day != filterDate.day) {
            continue;
          }
        }

        // Time check
        final startTimeStr = slot.startTime?.toString() ?? "";
        final endTimeStr = slot.endTime?.toString() ?? "";
        if (filterStartTime != null) {
          final slotStart = timeOfDayFromString(startTimeStr);
          if (slotStart == null || !isTimeOfDayBeforeOrEqual(filterStartTime, slotStart)) {
            continue;
          }
        }
        if (filterEndTime != null) {
          final slotEnd = timeOfDayFromString(endTimeStr.isNotEmpty ? endTimeStr : startTimeStr);
          if (slotEnd == null || !isTimeOfDayBeforeOrEqual(slotEnd, filterEndTime)) {
            continue;
          }
        }

        return true;
      }
      return false;
    }

    // 2. Check details
    if (details != null) {
      final startDtStr = details['start_datetime']?.toString() ?? details['date']?.toString();
      final endDtStr = details['end_datetime']?.toString();

      if (startDtStr != null && startDtStr.isNotEmpty) {
        final startDt = DateTime.tryParse(startDtStr);
        if (startDt != null) {
          if (filterDate != null) {
            if (startDt.year != filterDate.year ||
                startDt.month != filterDate.month ||
                startDt.day != filterDate.day) {
              return false;
            }
          }

          if (filterStartTime != null) {
            final startTod = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
            if (!isTimeOfDayBeforeOrEqual(filterStartTime, startTod)) {
              return false;
            }
          }

          if (filterEndTime != null) {
            TimeOfDay endTod = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
            if (endDtStr != null && endDtStr.isNotEmpty) {
              final endDt = DateTime.tryParse(endDtStr);
              if (endDt != null) {
                endTod = TimeOfDay(hour: endDt.hour, minute: endDt.minute);
              }
            }
            if (!isTimeOfDayBeforeOrEqual(endTod, filterEndTime)) {
              return false;
            }
          }

          return true;
        }
      }
    }

    // 3. Fallback to serializerDate
    if (serializerDate != null && serializerDate.isNotEmpty) {
      final dt = DateTime.tryParse(serializerDate);
      if (dt != null) {
        if (filterDate != null) {
          if (dt.year != filterDate.year ||
              dt.month != filterDate.month ||
              dt.day != filterDate.day) {
            return false;
          }
        }
        if (filterStartTime != null) {
          final startTod = TimeOfDay(hour: dt.hour, minute: dt.minute);
          if (!isTimeOfDayBeforeOrEqual(filterStartTime, startTod)) {
            return false;
          }
        }
        if (filterEndTime != null) {
          final startTod = TimeOfDay(hour: dt.hour, minute: dt.minute);
          if (!isTimeOfDayBeforeOrEqual(startTod, filterEndTime)) {
            return false;
          }
        }
        return true;
      }
    }

    return false;
  }
}
