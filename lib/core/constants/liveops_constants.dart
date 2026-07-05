/// LiveOps events that are visible but not yet playable (no unique puzzle backend).
abstract final class LiveOpsConstants {
  static const lockedEventSlugs = {
    'champions_league_week',
    'matchday-weekend',
  };

  static bool isEventLocked(String slug) => lockedEventSlugs.contains(slug);
}
