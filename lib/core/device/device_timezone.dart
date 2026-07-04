/// Device local timezone offset for server-side daily quotas.
class DeviceTimezone {
  DeviceTimezone._();

  /// UTC offset in minutes (same sign as [DateTime.timeZoneOffset]).
  static int get offsetMinutes => DateTime.now().timeZoneOffset.inMinutes;
}
