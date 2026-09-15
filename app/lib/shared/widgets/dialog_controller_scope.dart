import 'package:flutter/widgets.dart';

/// Tiene in vita i controller di un dialog finche' la sua route e' montata.
///
/// PERCHE' ESISTE: `showDialog` completa il proprio Future nell'istante in cui
/// viene chiamato `Navigator.pop`, ma la route resta montata per tutta
/// l'animazione di uscita e in quei millisecondi continua a ricostruire i
/// TextField. Il codice tipico
///
/// ```dart
/// final ctrl = TextEditingController();
/// final result = await showDialog(...);
/// ctrl.dispose();          // troppo presto
/// ```
///
/// produce "A TextEditingController was used after being disposed" e, a
/// cascata, l'assertion `_dependents.isEmpty` di framework.dart: l'app viene
/// sostituita dalla schermata rossa anche se il salvataggio e' andato a buon
/// fine (difetto A-01/B-01 dell'audit del 2026-09-13).
///
/// Avvolgendo il contenuto del dialog in questo widget, il dispose avviene
/// quando la route viene davvero smontata, a animazione conclusa.
class DialogControllerScope extends StatefulWidget {
  const DialogControllerScope({
    required this.controllers,
    required this.child,
    super.key,
  });

  final List<ChangeNotifier> controllers;
  final Widget child;

  @override
  State<DialogControllerScope> createState() => _DialogControllerScopeState();
}

class _DialogControllerScopeState extends State<DialogControllerScope> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
