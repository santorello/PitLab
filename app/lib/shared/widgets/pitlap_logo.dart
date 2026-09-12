import 'package:flutter/material.dart';

/// Marchio PitLap (gomma RC). L'immagine ha già gli angoli arrotondati;
/// il widget aggiunge solo dimensione e un'ombra morbida opzionale.
class PitLapLogo extends StatelessWidget {
  const PitLapLogo({this.size = 38, this.shadow = true, super.key});

  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.235;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/brand/pitlap_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
