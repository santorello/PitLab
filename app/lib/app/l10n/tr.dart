// Traduzione a runtime dei testi italiani scritti direttamente nel codice.
// AppLang.code viene aggiornato da PitLapBootstrap a ogni cambio lingua.
import 'en_strings.dart';

class AppLang {
  AppLang._();
  static String code = 'it';
}

/// Testo italiano -> lingua corrente (fallback: il testo italiano).
String tr(String it) => AppLang.code == 'it' ? it : (enStrings[it] ?? it);

/// Come [tr] ma con segnaposto {0}, {1}, ... sostituiti da [args].
String trf(String it, List<Object?> args) {
  var s = tr(it);
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}

// Testi composti dal database (vista activity_feed e trigger delle notifiche)
// arrivano gia' scritti in italiano: qui li riconosciamo e li traduciamo.
const Map<String, String> _dbExact = {
  '🟢 Pista aperta': '🟢 Track open',
  '🔵 Pista bagnata': '🔵 Track wet',
  '🔴 Pista chiusa': '🔴 Track closed',
  '🟡 Pista limitata': '🟡 Track limited',
  '🚗 Piloti in arrivo': '🚗 Drivers on the way',
  'ℹ️ Aggiornamento scheda': 'ℹ️ Listing update',
  '⚪ Stato aggiornato': '⚪ Status updated',
  'La tua richiesta è stata approvata.': 'Your request has been approved.',
  'La tua richiesta non è stata approvata.': 'Your request was not approved.',
};
const Map<String, String> _dbPrefix = {
  '📍 Nuovo spot: ': '📍 New spot: ',
  'Nuovo commento: ': 'New comment: ',
  'Nuovo stato: ': 'New status: ',
};
const Map<String, String> _dbSuffix = {
  ' ha pubblicato una nuova build': ' published a new build',
  ' ha creato un nuovo evento': ' created a new event',
  ' ha iniziato a seguirti': ' started following you',
};

/// Traduce i testi generati dal database. Il resto passa invariato.
String trDb(String text) {
  if (AppLang.code == 'it') return text;
  final exact = _dbExact[text];
  if (exact != null) return exact;
  for (final e in _dbPrefix.entries) {
    if (text.startsWith(e.key)) return e.value + text.substring(e.key.length);
  }
  for (final e in _dbSuffix.entries) {
    if (text.endsWith(e.key)) {
      return text.substring(0, text.length - e.key.length) + e.value;
    }
  }
  return tr(text);
}

// Orari scritti a mano in italiano ("Lun chiuso; mar-ven 9:30-12:30 e ...").
// ponytail: sostituzione parola per parola, basta per i formati del censimento.
const Map<String, String> _hoursWords = {
  'lun': 'Mon', 'mar': 'Tue', 'mer': 'Wed', 'gio': 'Thu', 'ven': 'Fri',
  'sab': 'Sat', 'dom': 'Sun', 'lunedì': 'Monday', 'martedì': 'Tuesday',
  'mercoledì': 'Wednesday', 'giovedì': 'Thursday', 'venerdì': 'Friday',
  'sabato': 'Saturday', 'domenica': 'Sunday', 'chiuso': 'closed',
  'aperto': 'open', 'e': 'and', 'su': 'by', 'appuntamento': 'appointment',
  'festivi': 'holidays', 'dalle': 'from', 'alle': 'to', 'orario': 'hours',
  'continuato': 'non-stop',
};

String trHours(String text) {
  if (AppLang.code == 'it') return text;
  return text.replaceAllMapped(RegExp(r'[A-Za-zÀ-ÿ]+'), (m) {
    final w = m[0]!;
    final en = _hoursWords[w.toLowerCase()];
    return en ?? w;
  });
}
