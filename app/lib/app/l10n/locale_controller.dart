import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => const Locale('it');

  void setLocale(Locale? locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
