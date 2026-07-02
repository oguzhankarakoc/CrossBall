import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'shared/widgets/crossball_ui.dart';

class CrossBallApp extends ConsumerWidget {
  const CrossBallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    final themeMode = ref.watch(themeModeProvider).flutterThemeMode;

    return onboardingAsync.when(
      loading: () => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const _BootScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: PitchBackground(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to initialize: $error'),
              ),
            ),
          ),
        ),
      ),
      data: (onboardingComplete) {
        final router = createAppRouter(onboardingComplete: onboardingComplete);
        return MaterialApp.router(
          title: 'CrossBall',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Scaffold(
      body: PitchBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CrossBallLogo(size: 100),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Locks app to portrait orientation.
Future<void> lockPortraitOrientation() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}
