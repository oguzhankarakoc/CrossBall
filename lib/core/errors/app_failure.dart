import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable {
  const AppFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error']);
}

final class OfflineFailure extends AppFailure {
  const OfflineFailure([super.message = 'No internet connection']);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Validation failed']);
}

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication expired']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error']);
}

final class MaintenanceFailure extends AppFailure {
  const MaintenanceFailure([super.message = 'Maintenance in progress']);
}
