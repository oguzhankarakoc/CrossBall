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

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Validation failed']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error']);
}
