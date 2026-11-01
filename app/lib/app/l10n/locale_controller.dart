import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    // Prima visita: lingua del browser. Italiano solo per chi ha il browser in
    // italiano, inglese per tutti gli altri. Il profilo, se c'e', la sovrascrive.
    final code =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(code == 'it' ? 'it' : 'en');
  }

  void setLocale(Locale? locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
