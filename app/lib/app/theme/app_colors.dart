import 'package:flutter/material.dart';

class AppColors {
  // Core base colors
  static const graphite = Color(0xFF1F2329);
  static const steel = Color(0xFF4B5563);
  static const concrete = Color(0xFFD6D9DE);
  static const warmWhite = Color(0xFFF6F4EF);
  static const paper = Color(0xFFFAF8F3);
  static const signalOrange = Color(0xFFF97316);
  static const openGreen = Color(0xFF1F9D55);
  static const wetBlue = Color(0xFF2563EB);
  static const closedRed = Color(0xFFD14343);
  static const warningAmber = Color(0xFFD97706);
  static const panel = Color(0xFFFFFFFF);

  // Surface scale
  static const surfaceMuted = Color(0xFFF8F7F3);  // background card secondario
  static const surfaceCool = Color(0xFFEAEEF3);    // chip/pill background neutro
  static const surfaceWarm = Color(0xFFF5F3EE);    // info pill spot
  static const surfaceTaglinePill = Color(0xFFFFF0E6);
  static const surfaceImpersonation = Color(0xFFFFF4E6);

  // Border scale
  static const borderSubtle = Color(0xFFE8EAEE);  // bordi piu' leggeri di concrete
  static const borderStrong = concrete;            // alias semantico esplicito

  // Orange family (6 toni hardcoded, nominati)
  static const orange50 = Color(0xFFFFF4E6);       // alias di surfaceImpersonation per uso semantico
  static const orange100 = Color(0xFFFFF0E6);      // alias di surfaceTaglinePill
  static const orange200 = Color(0xFFFFD1B5);
  static const orange500 = signalOrange;           // 0xFFF97316
  static const orange700 = Color(0xFFC2410C);
  static const orange900 = Color(0xFF7C2D12);
  static const orangeText = Color(0xFF8A3C12);     // testo scuro su orange50/100

  // Status semantic (stati di pista)
  static const statusOpen = openGreen;
  static const statusClosed = closedRed;
  static const statusWarning = warningAmber;
  static const statusInfo = wetBlue;

  // onSurface variants
  static const onSurfaceMuted = steel;             // alias semantico

  // Dark mode colors
  static const darkSurface = Color(0xFF1B2027);
  static const darkScaffold = Color(0xFF12161B);
  static const darkBorder = Color(0xFF29303A);
}
