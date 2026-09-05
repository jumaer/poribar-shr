import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_localizations.dart';

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.bangla;

  void toggleLanguage() {
    state = state == AppLanguage.bangla ? AppLanguage.english : AppLanguage.bangla;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppLocalizations(lang);
});
