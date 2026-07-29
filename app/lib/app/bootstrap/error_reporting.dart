import 'dart:async';

import 'package:flutter/foundation.dart';

/// Centralized error reporting for PitLap.
///
/// In pre-beta there was NO global error handler: an uncaught exception could
/// kill the app (or a widget subtree) with zero telemetry. This module installs
/// the three standard Flutter safety nets and funnels everything through a
/// single [report] sink.
///
/// Sentry wiring (recommended next step, requires a DSN):
///   1. add `sentry_flutter: ^8.x` to pubspec.yaml dependencies
///   2. pass `--dart-define=SENTRY_DSN=...` in the build
///   3. in [init], if the DSN is non-empty call `SentryFlutter.init(...)` and
///      in [report] call `Sentry.captureException(error, stackTrace: stack)`.
/// The structure below is intentionally ready for that drop-in.
class AppErrorReporter {
  const AppErrorReporter._();

  static const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Whether an external crash reporter is configured.
  static bool get hasRemoteReporter => _sentryDsn.isNotEmpty;

  /// Installs global handlers. Call once, before `runApp`.
  static void init() {
    // 1. Errors thrown inside the Flutter framework (build/layout/paint).
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      report(
        details.exception,
        details.stack,
        context: details.context?.toDescription(),
        fatal: false,
      );
    };

    // 2. Uncaught async errors that reach the platform dispatcher.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack, context: 'PlatformDispatcher', fatal: true);
      return true; // handled: prevents a hard crash where possible.
    };
  }

  /// Single sink for every captured error.
  static void report(
    Object error,
    StackTrace? stack, {
    String? context,
    bool fatal = false,
  }) {
    final tag = fatal ? 'FATAL' : 'ERROR';
    final where = context == null ? '' : ' [$context]';
    debugPrint('PitLap·$tag$where: $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack, label: 'PitLap·$tag$where');
    }

    // TODO(beta): when a Sentry DSN is provided, forward here:
    // if (hasRemoteReporter) Sentry.captureException(error, stackTrace: stack);
  }

  /// Runs [body] inside a guarded zone so even errors escaping async gaps
  /// are captured rather than silently lost.
  static Future<void> runGuarded(FutureOr<void> Function() body) {
    return runZonedGuarded<Future<void>>(
      () async => body(),
      (error, stack) => report(error, stack, context: 'runZonedGuarded', fatal: true),
    ) ?? Future<void>.value();
  }
}
