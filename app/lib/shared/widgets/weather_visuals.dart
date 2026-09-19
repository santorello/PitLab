import 'package:flutter/material.dart';

/// Colori e icona della card meteo, uguali in home e nel dettaglio pista.
/// Chiave: codice WMO di Open-Meteo + probabilita' di pioggia in percentuale.
class WeatherPalette {
  const WeatherPalette({
    required this.top,
    required this.bottom,
    required this.accent,
    required this.strong,
    required this.soft,
    required this.chipBg,
    required this.chipText,
  });

  final Color top;
  final Color bottom;
  final Color accent;
  final Color strong;
  final Color soft;
  final Color chipBg;
  final Color chipText;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, bottom],
      );
}

WeatherPalette weatherPalette(int code, int rain) {
  // Pioggia / rovesci -> teal-verde acqua
  if (code >= 60 || rain >= 65) {
    return const WeatherPalette(
      top: Color(0xFFE1F5EE),
      bottom: Color(0xFF9FE1CB),
      accent: Color(0xFF1D9E75),
      strong: Color(0xFF085041),
      soft: Color(0xFF0F6E56),
      chipBg: Color(0xFF7FD3B6),
      chipText: Color(0xFF04342C),
    );
  }
  // Nebbia -> grigio
  if (code >= 45) {
    return const WeatherPalette(
      top: Color(0xFFF1EFE8),
      bottom: Color(0xFFD3D1C7),
      accent: Color(0xFF5F5E5A),
      strong: Color(0xFF2C2C2A),
      soft: Color(0xFF5F5E5A),
      chipBg: Color(0xFFC4C2B8),
      chipText: Color(0xFF2C2C2A),
    );
  }
  // Nuvoloso -> azzurro
  if (code >= 3 || rain >= 35) {
    return const WeatherPalette(
      top: Color(0xFFE6F1FB),
      bottom: Color(0xFFB5D4F4),
      accent: Color(0xFF378ADD),
      strong: Color(0xFF0C447C),
      soft: Color(0xFF185FA5),
      chipBg: Color(0xFF9CC6EF),
      chipText: Color(0xFF042C53),
    );
  }
  // Sereno -> ambra calda
  return const WeatherPalette(
    top: Color(0xFFFCEFD6),
    bottom: Color(0xFFF8C66B),
    accent: Color(0xFFBA7517),
    strong: Color(0xFF633806),
    soft: Color(0xFF854F0B),
    chipBg: Color(0xFFF3B44E),
    chipText: Color(0xFF412402),
  );
}

IconData weatherIcon(int code, int rain) {
  if (code >= 60 || rain >= 65) return Icons.water_drop_outlined;
  if (code >= 45) return Icons.foggy;
  if (code >= 3 || rain >= 35) return Icons.cloud_outlined;
  return Icons.wb_sunny_outlined;
}
