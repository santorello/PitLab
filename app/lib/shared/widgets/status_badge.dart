import 'package:flutter/material.dart';

import 'pill.dart';

/// Tipo di stato per un StatusBadge.
enum StatusBadgeKind {
  /// Pista aperta, stato positivo.
  open,

  /// Pista chiusa, stato negativo.
  closed,

  /// Evento pianificato, stato informativo.
  scheduled,

  /// Stato neutro/sconosciuto.
  neutral,
}

/// Badge specializzato per stati pista.
///
/// Visualizza uno stato semantico (aperto, chiuso, pianificato) con icona
/// e colore appropriato. Usa internamente [Pill] con tono corrispondente.
///
/// Esempio:
/// ```dart
/// StatusBadge(
///   label: 'APERTA',
///   kind: StatusBadgeKind.open,
/// )
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.kind,
    this.leadingIcon,
    super.key,
  });

  /// Testo dello stato (es. "APERTA", "CHIUSA").
  final String label;

  /// Tipo di stato per la colorazione semantica.
  final StatusBadgeKind kind;

  /// Icona opzionale a sinistra del label.
  final IconData? leadingIcon;

  /// Mappa [StatusBadgeKind] a [PillTone] semantico.
  PillTone _resolveTone() {
    return switch (kind) {
      StatusBadgeKind.open => PillTone.success,
      StatusBadgeKind.closed => PillTone.danger,
      StatusBadgeKind.scheduled => PillTone.info,
      StatusBadgeKind.neutral => PillTone.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: label,
      icon: leadingIcon,
      tone: _resolveTone(),
    );
  }
}
