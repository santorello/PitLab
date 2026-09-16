import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Margine interno dei riquadri principali: [wide] su tablet/PC, 16 su
  /// telefono. Sostituisce gli `EdgeInsets.all(24)` fissi che su uno schermo
  /// da 360 px lasciavano al contenuto poco piu' di 260 px.
  static EdgeInsets card(BuildContext context, [double wide = xl]) =>
      EdgeInsets.all(
        AppBreakpoints.isPhone(MediaQuery.sizeOf(context).width) ? lg : wide,
      );
}
