import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL della pagina di donazione (es. `https://paypal.me/tuohandle`).
///
/// Valorizzato a build time tramite `--dart-define-from-file=config/<env>.json`
/// (chiave `DONATION_URL`). Se vuoto il pulsante non viene mostrato: così in
/// un ambiente non configurato non compare mai un link rotto.
const String kDonationUrl = String.fromEnvironment('DONATION_URL');

bool get isDonationEnabled => kDonationUrl.isNotEmpty;

/// Apre la pagina di donazione nel browser esterno.
///
/// NOTA DI POLICY — non modificare senza rileggere la Payments policy di Google
/// Play: la donazione deve restare volontaria e NON dare diritto ad alcun
/// contenuto o vantaggio digitale (nessun PitCoin, nessun badge, nessuna
/// funzione sbloccata). Solo a questa condizione Google la qualifica come
/// "peer-to-peer payment" ed è esente dall'obbligo di Google Play Billing.
/// Riconoscere una ricompensa in-app trasformerebbe la donazione in acquisto
/// digitale, soggetto a Play Billing e relative commissioni.
Future<void> openDonationPage(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(kDonationUrl);
  if (uri == null) {
    return;
  }
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Impossibile aprire la pagina di donazione'),
      ),
    );
  }
}

/// Pulsante "Offri un caffè allo sviluppatore".
///
/// Si auto-nasconde se [kDonationUrl] non è configurato.
class CoffeeButton extends StatelessWidget {
  const CoffeeButton({this.color = Colors.white, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!isDonationEnabled) {
      return const SizedBox.shrink();
    }
    return IconButton(
      onPressed: () => openDonationPage(context),
      icon: Icon(Icons.local_cafe_outlined, color: color),
      tooltip: 'Offri un caffè allo sviluppatore',
    );
  }
}
