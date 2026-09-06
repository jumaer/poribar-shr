import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'app_localizations.dart';
export 'app_localizations.dart';

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    _loadPersistedLanguage();
    return AppLanguage.bangla;
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final saved = await AppDatabase().appSettingsDao.getSetting('language');
      if (saved != null && saved.isNotEmpty) {
        final lang = saved == 'english' ? AppLanguage.english : AppLanguage.bangla;
        if (state != lang) {
          state = lang;
        }
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> toggleLanguage({String? userPhone}) async {
    final next = state == AppLanguage.bangla ? AppLanguage.english : AppLanguage.bangla;
    await setLanguage(next, userPhone: userPhone);
  }

  Future<void> setLanguage(AppLanguage language, {String? userPhone}) async {
    state = language;
    final langStr = language == AppLanguage.english ? 'english' : 'bangla';
    
    // 1. Save to local SQLite
    try {
      await AppDatabase().appSettingsDao.setSetting('language', langStr);
    } catch (_) {}

    // 2. Save to Firestore if userPhone is available
    if (userPhone != null && userPhone.isNotEmpty) {
      try {
        final clean = userPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
        await FirebaseFirestore.instance.collection('users').doc(clean).set({
          'language': langStr,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Language preference saved to Firestore for $clean: $langStr');
      } catch (e) {
        debugPrint('Error syncing language to Firestore: $e');
      }
    }
  }

  /// Sync language setting directly from user's Firestore profile
  Future<void> syncFromFirestore(String userPhone) async {
    if (userPhone.isEmpty) return;
    try {
      final clean = userPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      final doc = await FirebaseFirestore.instance.collection('users').doc(clean).get();
      if (doc.exists && doc.data() != null) {
        final langStr = doc.data()?['language']?.toString();
        if (langStr != null && langStr.isNotEmpty) {
          final lang = langStr == 'english' ? AppLanguage.english : AppLanguage.bangla;
          state = lang;
          await AppDatabase().appSettingsDao.setSetting('language', langStr);
        }
      }
    } catch (e) {
      debugPrint('Error syncing language from Firestore: $e');
    }
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppLocalizations(lang);
});

final appLocaleProvider = Provider<Locale>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return lang == AppLanguage.english ? const Locale('en') : const Locale('bn');
});

