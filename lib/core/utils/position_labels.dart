/// Abbreviate football positions for compact search cards.
abstract final class PositionLabels {
  static String abbreviate(String? position) {
    if (position == null || position.trim().isEmpty) return '—';
    final raw = position.trim().toUpperCase();
    if (raw.length <= 4 && !raw.contains(' ')) return raw;

    return switch (raw) {
      'GOALKEEPER' || 'GK' => 'GK',
      'DEFENDER' || 'BACK' => 'CB',
      'MIDFIELDER' || 'MIDFIELD' => 'CM',
      'FORWARD' || 'STRIKER' => 'ST',
      'ATTACKING MIDFIELD' || 'ATTACKING MIDFIELDER' => 'CAM',
      'DEFENSIVE MIDFIELD' || 'DEFENSIVE MIDFIELDER' => 'CDM',
      'CENTRE-BACK' || 'CENTER BACK' || 'CENTRE BACK' => 'CB',
      'LEFT-BACK' || 'LEFT BACK' => 'LB',
      'RIGHT-BACK' || 'RIGHT BACK' => 'RB',
      'LEFT WING' || 'LEFT WINGER' => 'LW',
      'RIGHT WING' || 'RIGHT WINGER' => 'RW',
      'CENTRE-FORWARD' || 'CENTER FORWARD' => 'CF',
      _ => raw.split(RegExp(r'\s+')).first.length <= 4
          ? raw.split(RegExp(r'\s+')).first
          : raw.substring(0, 3),
    };
  }
}
