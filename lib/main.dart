import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/ads/ads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await lockPortraitOrientation();

  try {
    await AppConfig.load();
  } catch (e, st) {
    debugPrint('AppConfig.load failed: $e\n$st');
  }

  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey, // ignore: deprecated_member_use
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      debugPrint('Supabase.initialize failed: $e\n$st');
    }
  }

  final container = ProviderContainer();
  if (AppConfig.isAdMobEnabled) {
    try {
      await container.read(adsServiceProvider).initialize();
    } catch (e, st) {
      debugPrint('AdMob initialize failed: $e\n$st');
    }
  }
  container.dispose();

  runApp(const ProviderScope(child: CrossBallApp()));
}
