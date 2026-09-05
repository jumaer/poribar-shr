import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/private_vault_db_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PrivateVaultNotifier extends Notifier<List<PrivateVaultDbEntity>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  List<PrivateVaultDbEntity> build() {
    final user = ref.watch(authUserProvider);
    final uid = user?.uid ?? '';

    _loadLocalCache(uid);

    _sub?.cancel();
    if (uid.isNotEmpty) {
      _sub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private_vault')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snap) {
        final list = snap.docs.map((d) {
          final data = d.data();
          return PrivateVaultDbEntity(
            id: d.id,
            userId: data['userId']?.toString() ?? uid,
            category: data['category']?.toString() ?? '',
            title: data['title']?.toString() ?? '',
            secretContent: data['secretContent']?.toString() ?? '',
            timestamp: (data['timestamp'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        state = list;
        AppDatabase().privateVaultDao.insertAll(list);
      }, onError: (_) {
        // Offline fallback
        _loadLocalCache(uid);
      });
    }

    ref.onDispose(() {
      _sub?.cancel();
    });

    return [];
  }

  Future<void> _loadLocalCache(String uid) async {
    if (uid.isEmpty) return;
    try {
      final cached = await AppDatabase().privateVaultDao.findAll(uid);
      if (cached.isNotEmpty) {
        state = cached;
      }
    } catch (_) {}
  }

  Future<void> addItem(String title, String content, String category) async {
    final user = ref.read(authUserProvider);
    final uid = user?.uid ?? 'usr_current';
    final id = 'vault_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = PrivateVaultDbEntity(
      id: id,
      userId: uid,
      category: category,
      title: title,
      secretContent: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    state = [newItem, ...state];
    await AppDatabase().privateVaultDao.insertOrUpdate(newItem);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private_vault')
          .doc(id)
          .set({
        'id': id,
        'userId': uid,
        'category': category,
        'title': title,
        'secretContent': content,
        'timestamp': newItem.timestamp,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> deleteItem(String id) async {
    final user = ref.read(authUserProvider);
    final uid = user?.uid ?? 'usr_current';

    state = state.where((item) => item.id != id).toList();
    await AppDatabase().privateVaultDao.deleteById(id);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private_vault')
          .doc(id)
          .delete();
    } catch (_) {}
  }
}

final privateVaultProvider =
    NotifierProvider<PrivateVaultNotifier, List<PrivateVaultDbEntity>>(
  PrivateVaultNotifier.new,
);
