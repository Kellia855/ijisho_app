import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void toggle() {
    state = state == AppLanguage.english
        ? AppLanguage.kinyarwanda
        : AppLanguage.english;
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);
