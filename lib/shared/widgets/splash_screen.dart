import 'package:flutter/material.dart';

import 'crossball_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Scaffold(
      body: PitchBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CrossBallLogo(size: 120),
              const SizedBox(height: 24),
              Text(
                'CrossBall',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
