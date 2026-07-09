import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/crossball_error_panel.dart';

/// Maps [AppFailure] to localized user-facing copy.
String localizedFailureMessage(AppLocalizations l10n, Object? error) {
  if (error is AppFailure) {
    return switch (error) {
      OfflineFailure() => l10n.errorOffline,
      TimeoutFailure() => l10n.errorTimeout,
      NetworkFailure() => l10n.errorNetwork,
      ServerFailure() => l10n.errorServer,
      MaintenanceFailure() => l10n.maintenanceNoticeBody,
      AuthFailure() => l10n.errorAuth,
      ValidationFailure() => l10n.errorValidation,
      NotFoundFailure() => l10n.errorNotFound,
      CacheFailure() => l10n.errorGeneric,
    };
  }
  return localizedErrorMessage(l10n, 'unknown_error');
}

IconData failureIcon(Object? error) {
  if (error is OfflineFailure || error is NetworkFailure) return AppIcons.offline;
  if (error is MaintenanceFailure) return AppIcons.maintenance;
  return AppIcons.error;
}

/// Dedicated full-screen or inline error state with retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CrossBallErrorPanel(
      message: localizedFailureMessage(l10n, error),
      onRetry: onRetry,
      icon: failureIcon(error),
    );
  }
}

/// Offline-specific empty state.
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CrossBallErrorPanel(
      message: l10n.errorOffline,
      onRetry: onRetry,
      icon: AppIcons.offline,
    );
  }
}
