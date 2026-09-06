import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../domain/entities/amol_entity.dart';

class AmolService {
  static final AmolService _instance = AmolService._internal();
  factory AmolService() => _instance;
  AmolService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AmolItem> getDefaultAmols() {
    return const [
      AmolItem(
        id: 'subhanallah',
        nameBn: 'সুবহানাল্লাহ',
        nameAr: 'سُبْحَانَ اللَّهِ',
        virtue: 'আল্লাহ তায়ালা পবিত্র ও সর্বপ্রকার ত্রুটিমুক্ত',
        count: 0,
        target: 33,
      ),
      AmolItem(
        id: 'alhamdulillah',
        nameBn: 'আলহামদুলিল্লাহ',
        nameAr: 'الْحَمْدُ لِلَّهِ',
        virtue: 'সকল প্রশংসা মহান আল্লাহ তায়ালার জন্য',
        count: 0,
        target: 33,
      ),
      AmolItem(
        id: 'allahu_akbar',
        nameBn: 'আল্লাহু আকবার',
        nameAr: 'اللَّهُ أَكْبَرُ',
        virtue: 'আল্লাহ সর্বশ্রেষ্ঠ ও মহান',
        count: 0,
        target: 34,
      ),
      AmolItem(
        id: 'la_ilaha_illallah',
        nameBn: 'লা ইলাহা ইল্লাল্লাহ',
        nameAr: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
        virtue: 'আল্লাহ ব্যতীত কোনো উপাস্য নেই (শ্রেষ্ঠ জিকির)',
        count: 0,
        target: 100,
      ),
      AmolItem(
        id: 'astaghfirullah',
        nameBn: 'আস্তাগফিরুল্লাহ',
        nameAr: 'أَسْتَغْفِرُ اللَّهَ',
        virtue: 'গুনাহ মাফ ও রিজিক বৃদ্ধির মহৌষধ',
        count: 0,
        target: 100,
      ),
      AmolItem(
        id: 'durood_sharif',
        nameBn: 'সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম',
        nameAr: 'صَلَّىٰ اللَّهُ عَلَيْهِ وَسَلَّمَ',
        virtue: 'নবীজীর (সা.) প্রতি ভালোবাসা ও রহমত বর্ষণের উসিলা',
        count: 0,
        target: 100,
      ),
      AmolItem(
        id: 'la_hawla',
        nameBn: 'লা হাওলা ওয়ালা কুওয়াতা ইল্লা বিল্লাহ',
        nameAr: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        virtue: 'জান্নাতের অমূল্য গুপ্তধনসমূহের একটি',
        count: 0,
        target: 33,
      ),
      AmolItem(
        id: 'ayatul_kursi',
        nameBn: 'আয়াতুল কুরসি',
        nameAr: 'آيَةُ الْكُرْسِيِّ',
        virtue: 'কুরআনের শ্রেষ্ঠ আয়াত, নিরাপত্তা ও হেফাজতের রক্ষাকবচ',
        count: 0,
        target: 7,
      ),
    ];
  }

  List<AmolItem> _cachedTemplates = [];

  List<AmolItem> get currentTemplates {
    if (_cachedTemplates.isEmpty) {
      _cachedTemplates = getDefaultAmols();
    }
    return _cachedTemplates;
  }

  /// Stream Amol templates from Firestore (app_config/amol_templates)
  /// If missing on first app run, automatically seeds them to the server
  Stream<List<AmolItem>> streamAmolTemplates() {
    try {
      final docRef = _firestore.collection('app_config').doc('amol_templates');
      return docRef.snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) {
          _seedDefaultAmols(docRef);
          _cachedTemplates = getDefaultAmols();
          return _cachedTemplates;
        }
        final items = (snap.data()?['items'] as List?) ?? [];
        if (items.isEmpty) {
          _cachedTemplates = getDefaultAmols();
          return _cachedTemplates;
        }
        _cachedTemplates = items
            .map((m) => AmolItem.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        return _cachedTemplates;
      }).handleError((e) {
        debugPrint('streamAmolTemplates error: $e');
        return currentTemplates;
      });
    } catch (e) {
      debugPrint('streamAmolTemplates init error: $e');
      return Stream.value(currentTemplates);
    }
  }

  Future<void> _seedDefaultAmols(DocumentReference docRef) async {
    try {
      final defaults = getDefaultAmols().map((a) => a.toMap()).toList();
      await docRef.set({
        'items': defaults,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Seeded default amol templates into Firestore app_config/amol_templates');
    } catch (e) {
      debugPrint('Error seeding amol templates: $e');
    }
  }

  /// Add a brand new Amol item template directly into Firestore server
  Future<void> addNewAmolTemplate(AmolItem item) async {
    try {
      final docRef = _firestore.collection('app_config').doc('amol_templates');
      await docRef.set({
        'items': FieldValue.arrayUnion([item.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!_cachedTemplates.any((t) => t.id == item.id)) {
        _cachedTemplates.add(item);
      }
      debugPrint('New Amol template saved to Firestore: ${item.nameBn}');
    } catch (e) {
      debugPrint('Failed to save new amol template to Firestore: $e');
      rethrow;
    }
  }

  /// Save Amol progress to Firestore & cache in SQLite
  Future<void> saveUserAmolState({
    required String familyId,
    required String phone,
    required String memberName,
    required String memberRelation,
    required List<AmolItem> amols,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final totalCount = amols.fold<int>(0, (acc, item) => acc + item.count);

    // 1. Cache to SQLite
    try {
      final db = await AppDatabase().database;
      for (final a in amols) {
        await db.insert(
          'amols',
          {
            'amolId': a.id,
            'phoneNumber': cleanPhone,
            'familyId': familyId,
            'nameBn': a.nameBn,
            'nameAr': a.nameAr,
            'count': a.count,
            'target': a.target,
            'date': today,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}

    // 2. Sync to Firestore
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('amols')
          .doc(cleanPhone)
          .set({
        'phoneNumber': cleanPhone,
        'memberName': memberName,
        'memberRelation': memberRelation,
        'date': today,
        'totalCount': totalCount,
        'items': amols.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveUserAmolState error: $e');
    }
  }

  /// Stream a user's Amols from Firestore
  Stream<List<AmolItem>> streamUserAmols({
    required String familyId,
    required String phone,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('amols')
        .doc(cleanPhone)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        return currentTemplates;
      }
      final data = snap.data()!;
      final docDate = data['date']?.toString() ?? '';
      if (docDate != today) {
        // New day reset
        return currentTemplates;
      }
      final items = (data['items'] as List?) ?? [];
      if (items.isEmpty) return currentTemplates;
      return items.map((m) => AmolItem.fromMap(Map<String, dynamic>.from(m))).toList();
    });
  }

  /// Stream family members' Amol board
  Stream<List<Map<String, dynamic>>> streamFamilyAmolBoard(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('amols')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Like a family member's Amol
  Future<void> likeMemberAmol({
    required String familyId,
    required String targetPhone,
    required String senderName,
    required String senderPhone,
  }) async {
    final cleanTarget = targetPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final cleanSender = senderPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('amols')
          .doc(cleanTarget)
          .set({
        'likesCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([cleanSender]),
      }, SetOptions(merge: true));

      // Send in-app & push notification
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'আমলে লাইক পেয়েছেন ❤️',
        'body': '$senderName আপনার আজকের আমলে ভালোবাসা ও উৎসাহ পাঠিয়েছেন!',
        'type': 'amol_like',
        'targetPhone': cleanTarget,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      NotificationService().sendCustomPush(
        title: 'আমলে লাইক পেয়েছেন ❤️',
        body: '$senderName আপনার আজকের আমলে ভালোবাসা ও উৎসাহ পাঠিয়েছেন!',
        senderName: senderName,
        receiverId: cleanTarget,
        familyId: familyId,
        senderIsPermitted: true,
      );
    } catch (e) {
      debugPrint('likeMemberAmol error: $e');
    }
  }

  /// Send an Amol Reminder to another member
  Future<void> sendAmolReminder({
    required String familyId,
    required String targetPhone,
    required String senderName,
    required String amolName,
  }) async {
    final cleanTarget = targetPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'আমলের দাওয়াত 🤲',
        'body': '$senderName আপনাকে "$amolName" জিকির পড়ার রিমাইন্ডার পাঠিয়েছেন।',
        'type': 'amol_reminder',
        'targetPhone': cleanTarget,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      NotificationService().sendCustomPush(
        title: 'আমলের দাওয়াত 🤲',
        body: '$senderName আপনাকে "$amolName" জিকির পড়ার রিমাইন্ডার পাঠিয়েছেন।',
        senderName: senderName,
        receiverId: cleanTarget,
        familyId: familyId,
        senderIsPermitted: true,
      );
    } catch (e) {
      debugPrint('sendAmolReminder error: $e');
    }
  }
}

final amolTemplatesProvider = StreamProvider<List<AmolItem>>((ref) {
  return AmolService().streamAmolTemplates();
});
