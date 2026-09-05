import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore? get instance {
    try {
      _firestore ??= FirebaseFirestore.instance;
      return _firestore;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return;
      await firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return;
      await firestore.collection(collectionPath).doc(docId).delete();
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    String? orderByField,
    bool descending = true,
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
      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList(),
          );
    } catch (_) {
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
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    String? orderByField,
    bool descending = true,
  }) async {
    try {
      final firestore = instance;
      if (firestore == null) return [];
      Query query = firestore.collection(collectionPath);
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
