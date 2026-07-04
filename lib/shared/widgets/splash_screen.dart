import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'crossball_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);

    return Scaffold(
      body: PitchBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CrossBallLogo(size: 128),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'CROSSBALL',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Strategic Football Dashboard',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.lime,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
