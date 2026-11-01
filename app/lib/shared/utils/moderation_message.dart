/// Traduce l'errore del filtro contenuti DB in un messaggio per l'utente.
///
/// Il trigger `moderation_guard` alza: `PITLAP_MODERATION:<categoria>:<campo>`
/// Qui non si ripete la parola incriminata: dirla di nuovo non aiuta nessuno.
library;

import 'package:pitlap_app/app/l10n/tr.dart';

const String _prefix = 'PITLAP_MODERATION:';

/// Categoria e campo estratti dall'errore del trigger, null se non e' un blocco.
({String category, String field})? moderationHit(Object error) {
  final text = error.toString();
  final start = text.indexOf(_prefix);
  if (start < 0) return null;
  final parts = text.substring(start + _prefix.length).split(':');
  if (parts.isEmpty) return null;
  return (
    category: parts[0].trim(),
    field: parts.length > 1 ? parts[1].trim().split(RegExp(r'[^a-z_]')).first : '',
  );
}

/// null quando l'errore non viene dal filtro: il chiamante mostra il suo.
String? moderationMessage(Object error, {bool italian = true}) {
  final text = error.toString();
  final start = text.indexOf(_prefix);
  if (start < 0) return null;
  final parts = text.substring(start + _prefix.length).split(':');
  final category = parts.isEmpty ? '' : parts.first.trim();

  if (italian) {
    final base = tr('Il testo inserito non rispetta le regole della community PitLap');
    switch (category) {
      case 'minori':
        return trf('{0}: sono vietati i riferimenti sessuali che coinvolgono minori. Questo tipo di contenuto viene sempre bloccato.', [base]);
      case 'sessuale':
        return trf('{0}: contenuti sessuali espliciti non sono ammessi.', [base]);
      case 'bestemmia':
        return trf('{0}: le bestemmie non sono ammesse.', [base]);
      case 'odio':
        return trf('{0}: insulti discriminatori non sono ammessi.', [base]);
      case 'volgare':
        return trf('{0}: rimuovi il linguaggio volgare e riprova.', [base]);
      default:
        return trf('{0}. Modifica il testo e riprova.', [base]);
    }
  }

  const base = 'Your text does not meet the PitLap community rules';
  switch (category) {
    case 'minori':
      return '$base: sexual references involving minors are never allowed.';
    case 'sessuale':
      return '$base: explicit sexual content is not allowed.';
    case 'bestemmia':
      return '$base: blasphemy is not allowed.';
    case 'odio':
      return '$base: discriminatory insults are not allowed.';
    case 'volgare':
      return '$base: please remove the profanity and try again.';
    default:
      return '$base. Edit your text and try again.';
  }
}

/// Messaggio per il blocco dei limiti di frequenza (trigger `enforce_rate_limit`,
/// delta 2026-09-23-limiti-frequenza). null se l'errore e' un altro.
String? rateLimitMessage(Object error, {bool italian = true}) {
  final text = error.toString();
  if (!text.contains('rate_limited') &&
      !text.contains('Troppe azioni in poco tempo')) {
    return null;
  }
  return italian
      ? tr('Troppe azioni in poco tempo: riprova tra qualche minuto.')
      : 'Too many actions in a short time: please try again in a few minutes.';
}
