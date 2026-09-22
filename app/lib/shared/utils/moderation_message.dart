/// Traduce l'errore del filtro contenuti DB in un messaggio per l'utente.
///
/// Il trigger `moderation_guard` alza: `PITLAP_MODERATION:<categoria>:<campo>`
/// Qui non si ripete la parola incriminata: dirla di nuovo non aiuta nessuno.
library;

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
    const base = 'Il testo inserito non rispetta le regole della community PitLap';
    switch (category) {
      case 'minori':
        return '$base: sono vietati i riferimenti sessuali che coinvolgono minori. '
            'Questo tipo di contenuto viene sempre bloccato.';
      case 'sessuale':
        return '$base: contenuti sessuali espliciti non sono ammessi.';
      case 'bestemmia':
        return '$base: le bestemmie non sono ammesse.';
      case 'odio':
        return '$base: insulti discriminatori non sono ammessi.';
      case 'volgare':
        return '$base: rimuovi il linguaggio volgare e riprova.';
      default:
        return '$base. Modifica il testo e riprova.';
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
      ? 'Troppe azioni in poco tempo: riprova tra qualche minuto.'
      : 'Too many actions in a short time: please try again in a few minutes.';
}
