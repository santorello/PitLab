import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bootstrap/bootstrap.dart';
import 'app/bootstrap/app_config.dart';
import 'app/bootstrap/error_reporting.dart';

void main() {
  // Everything runs inside a guarded zone so that binding init, Supabase
  // init and the whole widget tree share one error-handling context.
  AppErrorReporter.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorReporter.init();

    if (AppConfig.hasSupabaseConfig) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabasePublishableKey,
      );
    }

    runApp(const ProviderScope(child: PitLapBootstrap()));
  });
}
