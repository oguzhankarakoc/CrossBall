import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/country_flags.dart';
import '../../core/utils/hint_display.dart';

enum CountryFlagSize {
  /// Avatar corner overlay (~16–18px).
  xs,

  /// Inline metadata next to labels (~18–20px).
  sm,

  /// Hint chips and emphasis rows (~22–24px).
  md,
}

/// Styled Unicode flag badge — consistent sizing across the app.
class CountryFlagBadge extends StatelessWidget {
  const CountryFlagBadge({
    super.key,
    required this.code,
    this.size = CountryFlagSize.sm,
    this.showBorder = true,
  });

  final String? code;
  final CountryFlagSize size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final flag = CountryFlags.emoji(code);
    if (flag.isEmpty) return const SizedBox.shrink();

    final dimension = switch (size) {
      CountryFlagSize.xs => 18.0,
      CountryFlagSize.sm => 20.0,
      CountryFlagSize.md => 24.0,
    };
    final fontSize = switch (size) {
      CountryFlagSize.xs => 11.0,
      CountryFlagSize.sm => 13.0,
      CountryFlagSize.md => 15.0,
    };

    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pitchDeep.withValues(alpha: 0.82),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1)
            : null,
        boxShadow: size == CountryFlagSize.xs
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        flag,
        style: TextStyle(fontSize: fontSize, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Flag + country name (+ optional position) for player metadata rows.
class NationalityLabel extends StatelessWidget {
  const NationalityLabel({
    super.key,
    required this.nationalityCode,
    this.position,
    this.style,
    this.maxLines = 1,
  });

  final String? nationalityCode;
  final String? position;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final hasNationality = CountryFlags.hasKnownNationality(nationalityCode);
    final hasPosition = position != null && position!.trim().isNotEmpty;

    if (!hasNationality && !hasPosition) return const SizedBox.shrink();

    final textStyle = style ??
        Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return Row(
      children: [
        if (hasNationality) ...[
          CountryFlagBadge(code: nationalityCode, size: CountryFlagSize.sm),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              [
                if (hasNationality) CountryFlags.displayName(nationalityCode),
                if (hasPosition) position!,
              ].join(' • '),
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          Flexible(
            child: Text(
              position!,
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Compact value for hint chips — flag + readable nationality label.
class NationalityHintValue extends StatelessWidget {
  const NationalityHintValue({
    super.key,
    required this.code,
    this.unknownLabel = '—',
    this.style,
  });

  final String code;
  final String unknownLabel;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (HintDisplayFormatter.isUnknown(code) ||
        !CountryFlags.hasKnownNationality(code)) {
      return Text(unknownLabel, style: style);
    }

    final label = CountryFlags.displayName(code);
    final flag = CountryFlags.emoji(code);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: style?.copyWith(fontSize: (style?.fontSize ?? 12) + 1)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
