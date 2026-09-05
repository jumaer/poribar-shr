import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import 'firestore_service.dart';

class SplashConfigService {
  static final SplashConfigService _instance = SplashConfigService._internal();
  factory SplashConfigService() => _instance;
  SplashConfigService._internal();

  String? _inMemoryCachedSplashImage;

  String? get cachedSplashImage => _inMemoryCachedSplashImage;

  /// Loads splash image from SQLite or Firestore
  Future<String?> getSplashImage({String? familyId}) async {
    if (_inMemoryCachedSplashImage != null) {
      return _inMemoryCachedSplashImage;
    }

    // 1. Try reading from local SQLite cache first (instant offline boot)
    try {
      final sqliteCached = await AppDatabase().appSettingsDao.getSetting('splash_image');
      if (sqliteCached != null && sqliteCached.isNotEmpty) {
        _inMemoryCachedSplashImage = sqliteCached;
        return _inMemoryCachedSplashImage;
      }
    } catch (_) {}

    try {
      if (familyId != null && familyId.isNotEmpty) {
        final famDoc = await FirestoreService().getDocument(
          collectionPath: 'families/$familyId/settings',
          docId: 'splash',
        );
        if (famDoc != null && famDoc['base64Image'] != null) {
          _inMemoryCachedSplashImage = famDoc['base64Image'] as String?;
          if (_inMemoryCachedSplashImage != null) {
            await AppDatabase().appSettingsDao.setSetting('splash_image', _inMemoryCachedSplashImage!);
          }
          return _inMemoryCachedSplashImage;
        }
      }

      // Fallback to global app settings
      final globalDoc = await FirestoreService().getDocument(
        collectionPath: 'app_settings',
        docId: 'splash',
      );
      if (globalDoc != null && globalDoc['base64Image'] != null) {
        _inMemoryCachedSplashImage = globalDoc['base64Image'] as String?;
        if (_inMemoryCachedSplashImage != null) {
          await AppDatabase().appSettingsDao.setSetting('splash_image', _inMemoryCachedSplashImage!);
        }
        return _inMemoryCachedSplashImage;
      }
    } catch (e) {
      debugPrint('Error fetching splash image: $e');
    }

    return null;
  }

  /// Updates the splash image in Firestore
  Future<void> updateSplashImage({
    required String familyId,
    required String base64Image,
    required String updatedBy,
  }) async {
    _inMemoryCachedSplashImage = base64Image;

    final data = {
      'base64Image': base64Image,
      'updatedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
      'time': DateTime.now().toIso8601String(),
    };

    // Save to local SQLite database for offline boot
    await AppDatabase().appSettingsDao.setSetting('splash_image', base64Image);

    // Save to family-level settings
    await FirestoreService().saveDocument(
      collectionPath: 'families/$familyId/settings',
      docId: 'splash',
      data: data,
    );

    // Also save as fallback app_settings
    await FirestoreService().saveDocument(
      collectionPath: 'app_settings',
      docId: 'splash',
      data: data,
    );
  }

  /// Resets splash image back to default
  Future<void> resetSplashImage({required String familyId}) async {
    _inMemoryCachedSplashImage = null;
    await AppDatabase().appSettingsDao.removeSetting('splash_image');

    await FirestoreService().deleteDocument(
      collectionPath: 'families/$familyId/settings',
      docId: 'splash',
    );

    await FirestoreService().deleteDocument(
      collectionPath: 'app_settings',
      docId: 'splash',
    );
  }

  /// Stream splash image updates in real time
  Stream<String?> splashImageStream(String familyId) {
    try {
      final firestore = FirebaseFirestore.instance;
      return firestore
          .collection('families/$familyId/settings')
          .doc('splash')
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final img = snapshot.data()!['base64Image'] as String?;
          _inMemoryCachedSplashImage = img;
          return img;
        }
        return null;
      });
    } catch (_) {
      return Stream.value(_inMemoryCachedSplashImage);
    }
  }
}
