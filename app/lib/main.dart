import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bootstrap/bootstrap.dart';
import 'app/bootstrap/app_config.dart';
import 'app/bootstrap/error_reporting.dart';

void main() {
  // Everything runs inside a guarded zone so that binding init, Supabase
  // init and the whole widget tree share one error-handling context.
  AppErrorReporter.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // URL puliti su web (path invece di hash): i link condivisi come /tracks o
    // /legal/privacy atterrano sulla pagina giusta. Richiede il fallback SPA
    // lato host (vedi web/_redirects per Cloudflare Pages).
    if (kIsWeb) {
      usePathUrlStrategy();
      // context.push aggiorna anche la barra degli indirizzi: aprendo una
      // build o una pista dalla lista, il link copiato o un refresh portano
      // alla pagina giusta invece che alla lista.
      GoRouter.optionURLReflectsImperativeAPIs = true;
    }
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
