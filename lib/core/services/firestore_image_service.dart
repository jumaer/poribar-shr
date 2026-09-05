import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/app_database.dart';

class FirestoreImageService {
  static final Map<String, Uint8List> _memoryCache = {};

  static String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  /// Saves the image base64 data to Firestore under `images/{imageId}`
  /// and caches it locally in SQLite. Returns the lightweight Firestore path `images/{imageId}`.
  static Future<String> saveImageToFirestore(String base64Data) async {
    final imageId = 'img_${DateTime.now().millisecondsSinceEpoch}';
    final path = 'images/$imageId';

    // 1. Cache bytes in memory
    try {
      final bytes = base64Decode(base64Data);
      _memoryCache[path] = bytes;
    } catch (_) {}

    // 2. Cache in local SQLite database for instant offline access
    try {
      await AppDatabase().appSettingsDao.set('cache_$path', base64Data);
    } catch (_) {}

    // 3. Upload to Firestore images collection
    try {
      await FirebaseFirestore.instance.collection('images').doc(imageId).set({
        'path': path,
        'data': base64Data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline fallback: will be available in SQLite locally
    }

    return path;
  }

  /// Retrieves base64 image data from memory, SQLite, or Firestore
  static Future<String?> getImageBase64(String pathOrData) async {
    if (!pathOrData.startsWith('images/')) {
      return pathOrData;
    }

    // 1. Check local SQLite cache
    final localData = await AppDatabase().appSettingsDao.get('cache_$pathOrData');
    if (localData != null && localData.isNotEmpty) {
      return localData;
    }

    // 2. Fetch from Firestore
    try {
      final doc = await FirebaseFirestore.instance.doc(pathOrData).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['data'] as String?;
        if (data != null && data.isNotEmpty) {
          await AppDatabase().appSettingsDao.set('cache_$pathOrData', data);
          return data;
        }
      }
    } catch (_) {}

    return null;
  }

  static Widget buildFirestoreImage({
    required String? base64Data,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (base64Data == null || base64Data.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
        child: const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 24),
      );
    }

    // Check if it's a Firestore image path
    if (base64Data.startsWith('images/')) {
      final path = base64Data;
      if (_memoryCache.containsKey(path)) {
        return _buildImageFromBytes(_memoryCache[path]!, width, height, fit, borderRadius);
      }

      return FutureBuilder<String?>(
        future: getImageBase64(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
            final bytes = base64ToBytes(snapshot.data!);
            if (bytes != null) {
              _memoryCache[path] = bytes;
              return _buildImageFromBytes(bytes, width, height, fit, borderRadius);
            }
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: borderRadius ?? BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                ),
              ),
            );
          }
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: borderRadius ?? BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 24),
          );
        },
      );
    }

    // Check if it's a local file path
    if (base64Data.startsWith('/') || base64Data.contains(':\\') || base64Data.contains(':/')) {
      try {
        final file = File(base64Data);
        if (file.existsSync()) {
          return SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
              child: Image.file(
                file,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (ctx, err, stack) => _errorPlaceholder(width, height, borderRadius),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    // Direct base64 string
    final bytes = base64ToBytes(base64Data);
    if (bytes == null) {
      return _errorPlaceholder(width, height, borderRadius);
    }

    return _buildImageFromBytes(bytes, width, height, fit, borderRadius);
  }

  static Widget _buildImageFromBytes(
    Uint8List bytes,
    double? width,
    double? height,
    BoxFit fit,
    BorderRadius? borderRadius,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _errorPlaceholder(width, height, borderRadius),
        ),
      ),
    );
  }

  static Widget _errorPlaceholder(double? width, double? height, BorderRadius? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
      child: const Icon(Icons.broken_image_outlined, color: AppColors.primaryRed, size: 24),
    );
  }
}
