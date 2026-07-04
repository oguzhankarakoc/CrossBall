import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/config/app_config.dart';

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=test
REMOTE_PUSH_ENABLED=true
FIREBASE_PROJECT_ID=crossball-test
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_IOS_API_KEY=AIza-test
FIREBASE_IOS_APP_ID=1:123456789012:ios:abc
FIREBASE_ANDROID_API_KEY=AIza-android
FIREBASE_ANDROID_APP_ID=1:123456789012:android:abc
''');
  });

  test('isRemotePushEnabled reads env flag', () {
    expect(AppConfig.isRemotePushEnabled, isTrue);
  });

  test('firebase env keys load from dotenv', () {
    expect(AppConfig.firebaseProjectId, 'crossball-test');
    expect(AppConfig.firebaseMessagingSenderId, '123456789012');
    expect(AppConfig.firebaseIosApiKey, 'AIza-test');
    expect(AppConfig.firebaseIosAppId, '1:123456789012:ios:abc');
    expect(AppConfig.firebaseAndroidApiKey, 'AIza-android');
  });
}
