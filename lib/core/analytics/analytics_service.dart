/// Analytics abstraction — swap PostHog / Firebase without changing call sites.
abstract interface class AnalyticsService {
  Future<void> track(String event, {Map<String, dynamic>? properties});
  Future<void> identify(String userId, {Map<String, dynamic>? traits});
}

class ConsoleAnalyticsService implements AnalyticsService {
  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    // ignore: avoid_print
    print('[Analytics] $event ${properties ?? {}}');
  }

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    // ignore: avoid_print
    print('[Analytics] identify $userId ${traits ?? {}}');
  }
}
