import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../debug/crossball_debug_log.dart';
import '../errors/app_failure.dart';
import 'api_config.dart';
import 'api_exception_parser.dart';

/// Raw HTTP response for endpoints with custom status semantics (e.g. daily-puzzle 503).
class ApiRawResponse {
  const ApiRawResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  Map<String, dynamic>? get jsonMap {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Production HTTP client for Supabase Edge Functions.
///
/// Features: timeouts, retries, auth headers, debug logging, [AppFailure] mapping.
class ApiHttpClient {
  ApiHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? timeout,
    bool throwOnError = true,
    int? retries,
  }) {
    return _request(
      method: 'GET',
      path: path,
      query: query,
      headers: headers,
      timeout: timeout,
      throwOnError: throwOnError,
      retries: retries,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? timeout,
    bool throwOnError = true,
    int? retries,
  }) {
    return _request(
      method: 'POST',
      path: path,
      query: query,
      headers: headers,
      body: body,
      timeout: timeout,
      throwOnError: throwOnError,
      retries: retries,
    );
  }

  Future<ApiRawResponse> getRaw(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (!ApiConfig.isConfigured) {
      throw const NetworkFailure('API not configured');
    }
    final uri = ApiConfig.functionUri(path, query: query);
    final response = await _send(
      method: 'GET',
      uri: uri,
      headers: {...ApiConfig.defaultHeaders, ...?headers},
      timeout: timeout ?? ApiConfig.receiveTimeout,
    );
    return ApiRawResponse(statusCode: response.statusCode, body: response.body);
  }

  Future<ApiRawResponse> postRaw(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (!ApiConfig.isConfigured) {
      throw const NetworkFailure('API not configured');
    }
    final uri = ApiConfig.functionUri(path, query: query);
    final response = await _send(
      method: 'POST',
      uri: uri,
      headers: {...ApiConfig.defaultHeaders, ...?headers},
      body: body,
      timeout: timeout ?? ApiConfig.receiveTimeout,
    );
    return ApiRawResponse(statusCode: response.statusCode, body: response.body);
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
    required bool throwOnError,
    int? retries,
  }) async {
    if (!ApiConfig.isConfigured) {
      if (throwOnError) throw const NetworkFailure('API not configured');
      return const {};
    }

    final uri = ApiConfig.functionUri(path, query: query);
    final mergedHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
    };
    final effectiveTimeout = timeout ?? ApiConfig.receiveTimeout;
    final maxAttempts = (retries ?? ApiConfig.maxRetries) + 1;

    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          cbDebug('HTTP', '$method ${uri.path}', {
            if (query != null && query.isNotEmpty) 'query': query,
            'attempt': attempt + 1,
          });
        }

        final response = await _send(
          method: method,
          uri: uri,
          headers: mergedHeaders,
          body: body,
          timeout: effectiveTimeout,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.body.isEmpty) return const {'ok': true};
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return {'ok': true, 'data': decoded};
        }

        final failure = ApiExceptionParser.fromResponse(response);
        if (!throwOnError) return const {};
        throw failure;
      } catch (e, st) {
        lastError = e;
        final failure = ApiExceptionParser.from(e, st);
        final retryable = failure is NetworkFailure ||
            failure is TimeoutFailure ||
            failure is OfflineFailure ||
            failure is ServerFailure;
        if (!retryable || attempt >= maxAttempts - 1) {
          if (!throwOnError) return const {};
          throw failure;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }

    if (!throwOnError) return const {};
    throw ApiExceptionParser.from(lastError ?? 'Request failed');
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    required Duration timeout,
  }) {
    final encoded = body == null ? null : jsonEncode(body);
    final Future<http.Response> future = switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: encoded),
      'PUT' => _client.put(uri, headers: headers, body: encoded),
      'DELETE' => _client.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported method: $method'),
    };
    return future.timeout(timeout);
  }

  void close() => _client.close();
}
