import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore? get instance {
    try {
      if (_firestore == null) {
        _firestore = FirebaseFirestore.instance;
        try {
          _firestore!.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } catch (_) {}
      }
      return _firestore;
    } catch (e) {
      debugPrint('FirestoreService: Cannot access FirebaseFirestore.instance: $e');
      return null;
    }
  }

  /// Translates Firebase errors into friendly localized Bengali messages
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'অনুমতি নেই! আপনার অ্যাকাউন্টের অ্যাক্সেস অনুমতি যাচাই করুন।';
        case 'resource-exhausted':
        case 'quota-exceeded':
          return 'ফায়ারবেস ক্লাউড কোটা সাময়িকভাবে শেষ। লোকাল ক্যাশ থেকে অফলাইনে পরিচালিত হচ্ছে।';
        case 'unavailable':
          return 'ইন্টারনেট সংযোগ বা সার্ভার সাময়িকভাবে বন্ধ। অফলাইন ক্যাশ সক্রিয় রয়েছে।';
        case 'not-found':
          return 'অনুরোধকৃত তথ্যটি সার্ভারে পাওয়া যায়নি।';
        default:
          return error.message ?? 'সার্ভার সংযোগে সমস্যা হয়েছে।';
      }
    }
    return error?.toString() ?? 'অপ্রত্যাশিত সমস্যা দেখা দিয়েছে।';
  }

  Future<void> saveDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) {
        throw Exception('Firebase Firestore চালু নেই বা কনফিগার করা হয়নি');
      }
      await firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveDocument error at $collectionPath/$docId: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return;
      await firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteDocument error at $collectionPath/$docId: $e');
      rethrow;
    }
  }

  /// Streams collection with an optimized limit (default 50) to protect Firebase Spark Free Tier limits
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    String? orderByField,
    bool descending = true,
    int? limit = 50,
  }) {
    try {
      final firestore = instance;
      if (firestore == null) {
        return Stream.value([]);
      }
      Query query = firestore.collection(collectionPath);
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList(),
          );
    } catch (e) {
      debugPrint('FirestoreService.streamCollection error at $collectionPath: $e');
      return Stream.value([]);
    }
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return null;
      final doc = await firestore.collection(collectionPath).doc(docId).get();
      return doc.data();
    } catch (e) {
      debugPrint('FirestoreService.getDocument error at $collectionPath/$docId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    String? orderByField,
    bool descending = true,
    int? limit = 50,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return [];
      Query query = firestore.collection(collectionPath);
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('FirestoreService.getCollection error at $collectionPath: $e');
      return [];
    }
  }
}
