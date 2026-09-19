import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'moderation_message.dart';

/// Registra un blocco del filtro contenuti, per capire se e' troppo aggressivo.
///
/// ponytail: la scrittura parte dal client perche' il trigger alza un'eccezione
/// e Postgres non ha transazioni autonome: un insert di log dentro lo stesso
/// statement verrebbe annullato insieme al resto. Il log serve a tarare i
/// termini, non a difendere: il blocco vero resta il trigger, che nessuno
/// aggira. Se un client malevolo non logga, ha comunque fallito l'inserimento.
/// Fire and forget: un log che fallisce non deve disturbare l'utente.
void logModerationBlock(
  SupabaseClient? client,
  Object error, {
  required String source,
  String? sample,
}) {
  final hit = moderationHit(error);
  if (client == null || hit == null) return;
  client.rpc('log_moderation_block', params: {
    'p_category': hit.category,
    'p_source': source,
    'p_field': hit.field,
    'p_sample': sample,
  }).catchError((Object e) {
    debugPrint('[Moderation] log fallito: $e');
    return null;
  });
}
