import 'package:crossball/core/errors/app_failure.dart';
import 'package:crossball/core/network/api_exception_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ApiExceptionParser', () {
    test('maps 503 to MaintenanceFailure', () {
      final failure = ApiExceptionParser.fromResponse(
        http.Response('{"error":"maintenance"}', 503),
      );
      expect(failure, isA<MaintenanceFailure>());
    });

    test('maps socket-style errors to OfflineFailure', () {
      final failure = ApiExceptionParser.from(
        const OfflineFailure(),
      );
      expect(failure, isA<OfflineFailure>());
    });
  });
}
