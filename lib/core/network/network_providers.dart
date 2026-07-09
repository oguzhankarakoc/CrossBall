import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_http_client.dart';

final apiHttpClientProvider = Provider<ApiHttpClient>((ref) {
  final client = ApiHttpClient();
  ref.onDispose(client.close);
  return client;
});
