import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router_provider.dart';
import 'features/economy/presentation/achievement_unlock_listener.dart';
import 'core/theme/theme_resolver.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'shared/widgets/crossball_ui.dart';
import 'core/routing/deep_link_listener.dart';

const _localizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class CrossBallApp extends ConsumerWidget {
  const CrossBallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    final themePref = ref.watch(themeModeProvider);
    final themes = resolveAppThemes(themePref);
    final localePref = ref.watch(localeProvider);
    final locale = resolveAppLocale(localePref);

    Locale? localeListResolutionCallback(List<Locale>? locales, Iterable<Locale> supported) {
      if (localePref != AppLocale.system) return locale;
      for (final deviceLocale in locales ?? const <Locale>[]) {
        if (deviceLocale.languageCode == 'tr') return const Locale('tr');
        if (deviceLocale.languageCode == 'de') return const Locale('de');
        if (deviceLocale.languageCode == 'en') return const Locale('en');
      }
      return const Locale('en');
    }

    return onboardingAsync.when(
      loading: () => MaterialApp(
        theme: themes.light,
        darkTheme: themes.dark,
        themeMode: themes.mode,
        locale: locale,
        localizationsDelegates: _localizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: localeListResolutionCallback,
        home: const _BootScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        theme: themes.light,
        darkTheme: themes.dark,
        themeMode: themes.mode,
        locale: locale,
        localizationsDelegates: _localizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: localeListResolutionCallback,
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
      data: (_) {
        final router = ref.watch(appRouterProvider);
        return AchievementUnlockListener(
          child: DeepLinkListener(
            router: router,
            child: MaterialApp.router(
              title: 'CrossBall',
              debugShowCheckedModeBanner: false,
              theme: themes.light,
              darkTheme: themes.dark,
              themeMode: themes.mode,
              locale: locale,
              localizationsDelegates: _localizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeListResolutionCallback: localeListResolutionCallback,
              routerConfig: router,
            ),
          ),
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
