import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/l10n/generated/app_localizations.dart';

// ── URL base pubblica ─────────────────────────────────────────────────────
//
// Su Web (kIsWeb = true) viene rilevata automaticamente da Uri.base, che
// riflette l'origin corrente del browser (es. https://pitlap.app).
// In ambienti non-web (Android, test) si usa questa costante come fallback.
//
// Per personalizzare in produzione basta cambiare questa stringa;
// non serve aggiungere dipendenze.
const String kPublicBaseUrl = 'https://pitlap.app';

/// Restituisce il link canonico per un'entità.
///
/// Le rotte seguono lo schema go_router definito in app_router.dart:
///   track   -> /track/:slug
///   shop    -> /shop/:slug
///   event   -> /event/:eventId
///   spot    -> /spot/:slug
///   user_build -> /builds   (nessuna pagina dettaglio build dedicata; link alla lista)
///   community_event -> /event/:id  (stesso path degli eventi pubblici)
String buildEntityLink(String entityType, String entityId) {
  final base = _resolveBase();
  final path = switch (entityType) {
    'track' => '/track/$entityId',
    'shop' => '/shop/$entityId',
    'event' => '/event/$entityId',
    'community_event' => '/event/$entityId',
    'spot' => '/spot/$entityId',
    'user_build' => '/builds',
    _ => '/',
  };
  return '$base$path';
}

String _resolveBase() {
  // Su web usiamo l'origin del browser. Uri.base ha sempre scheme+authority.
  // Esempio: https://pitlap.app  oppure  http://localhost:4000
  try {
    final uri = Uri.base;
    if (uri.hasScheme && uri.hasAuthority && uri.scheme.startsWith('http')) {
      return '${uri.scheme}://${uri.authority}';
    }
  } catch (_) {
    // Siamo in ambiente non-web oppure Uri.base non è disponibile.
  }
  return kPublicBaseUrl;
}

/// Copia il link canonico dell'entità negli appunti e mostra una snackbar.
Future<void> shareEntity({
  required BuildContext context,
  required String entityType,
  required String entityId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final link = buildEntityLink(entityType, entityId);
  await Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.shareLinkCopied)),
  );
}
