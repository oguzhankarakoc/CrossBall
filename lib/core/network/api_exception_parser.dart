import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';

/// Maps transport and HTTP failures into [AppFailure] for UI localization.
abstract final class ApiExceptionParser {
  static AppFailure from(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) {
      return const TimeoutFailure();
    }
    if (error is SocketException) {
      return const OfflineFailure();
    }
    if (error is HttpException) {
      return NetworkFailure(error.message);
    }
    if (error is FormatException) {
      return const ServerFailure('Invalid server response');
    }
    return const ServerFailure();
  }

  static AppFailure fromResponse(http.Response response) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      return const AuthFailure();
    }
    if (status == 404) {
      return const NotFoundFailure();
    }
    if (status == 503) {
      return const MaintenanceFailure();
    }
    if (status >= 500) {
      return ServerFailure(_extractMessage(response.body) ?? 'Server error');
    }
    if (status >= 400) {
      return ValidationFailure(_extractMessage(response.body) ?? 'Request failed');
    }
    return NetworkFailure(_extractMessage(response.body) ?? 'Network error');
  }

  static String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['error'] as String? ??
            json['message'] as String? ??
            json['error_code'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
