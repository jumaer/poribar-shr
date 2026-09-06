import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/serverkey.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../domain/entities/amol_entity.dart';
import '../domain/entities/surah_dua_entity.dart';

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
    }
  }

  /// Stream family-specific custom Amols
  Stream<List<AmolItem>> streamFamilyCustomAmols(String familyId) {
    if (familyId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('custom_amols')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AmolItem.fromMap(doc.data())).toList())
        .handleError((e) {
          debugPrint('streamFamilyCustomAmols error: $e');
          return <AmolItem>[];
        });
  }

  /// Save custom Amol to the family and global templates
  Future<void> saveCustomFamilyAmol(String familyId, AmolItem item) async {
    try {
      if (familyId.isNotEmpty) {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('custom_amols')
            .doc(item.id)
            .set(item.toMap(), SetOptions(merge: true));
      }
      await addNewAmolTemplate(item);
    } catch (e) {
      debugPrint('saveCustomFamilyAmol error: $e');
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

  /// Default Quranic Surahs & Duas
  List<SurahDuaEntity> getDefaultSurahsAndDuas() {
    return const [
      SurahDuaEntity(
        id: ServerKey.keyDuaQunut,
        titleBn: 'দুআ কুনুত (বিতর নামাজ)',
        titleAr: 'دعاء القنوت',
        surahNumber: 'বিতর নামাজের অপরিহার্য দুআ',
        arabicScript: 'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ وَنَشْكُرُكَ وَلَا نَكْفُرُكَ وَنَخْلَعُ وَنَتْرُكُ مَنْ يَفْجُرُكَ ، اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَلَكَ نُصَلِّي وَنَسْجُدُ وَإِلَيْكَ نَسْعَى وَنَحْفِدُ نَرْجُو رَحْمَتَكَ وَنَخْشَى عَذَابَكَ إِنَّ عَذَابَكَ بِالْكُفَّارِ مُلْحِقٌ',
        pronunciationBn: 'উচ্চারণ: আল্লা-হুম্মা ইন্না- নাসতা‘ঈনুকা ওয়া নাসতাগফিরুকা ওয়া নু’মিনু বিকা ওয়া নাতাওয়াক্কালু ‘আলাইকা ওয়া নুছনী ‘আলাইকাল খইর, ওয়া নাশকুরুকা ওয়ালা- নাকফুরুকা ওয়া নাখলা‘উ ওয়া নাতরুকু মাই ইয়াফজুরুকা। আল্লা-হুম্মা ইয়্যা-কা না‘বুদু ওয়া লাকা নুসল্লী ওয়া নাসজুদু ওয়া ইলাইকা নাস‘আ- ওয়া নাহফিদ, নারজু রহমাতাকা ওয়া নাখশা- ‘আযা-বাকা ইন্না ‘আযা-বাকা বিল কুফফা-রি মুলহিক্ব।',
        meaningBn: 'অর্থ: হে আল্লাহ! আমরা আপনার নিকট সাহায্য প্রার্থনা করছি, আপনার নিকট ক্ষমা ভিক্ষা করছি, আপনার প্রতি বিশ্বাস স্থাপন করছি এবং আপনার উপর ভরসা করছি। আপনার উত্তম প্রশংসা করছি, আপনার কৃতজ্ঞতা প্রকাশ করছি এবং অকৃতজ্ঞ হচ্ছি না। যে ব্যক্তি আপনার অবাধ্য হয় তাকে বর্জন ও পরিত্যাগ করছি। হে আল্লাহ! আমরা কেবল আপনারই ইবাদত করি, আপনার জন্যই নামাজ পড়ি এবং সিজদা করি। আপনার দিকেই দৌড়াই ও এগিয়ে যাই। আমরা আপনার রহমতের আশা করি এবং আপনার শাস্তিকে ভয় করি। নিশ্চয়ই আপনার শাস্তি কাফেরদের ওপর কার্যকর হবে।',
        virtue: 'হাদিস অনুযায়ী বিতর নামাজে কুনুত পাঠ করা সুন্নাত যা গুনাহ মাফ ও আল্লাহর সান্নিধ্য অর্জনের অন্যতম মাধ্যম।',
      ),
      SurahDuaEntity(
        id: ServerKey.keySuraArRahman,
        titleBn: 'সূরা আর-রহমান (কুরআনের সৌন্দর্য)',
        titleAr: 'سورة الرحمن',
        surahNumber: 'সূরা নং ৫৫ (মাক্কী/মাদানী, ৭৮ আয়াত)',
        arabicScript: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الرَّحْمَٰنُ ۝ عَلَّمَ الْقُرْآنَ ۝ خَلَقَ الْإِنْسَانَ ۝ عَلَّمَهُ الْبَيَانَ ۝ الشَّمْسُ وَالْقَمَرُ بِحُسْبَانٍ ۝ وَالنَّجْمُ وَالشَّجَرُ يَسْجُدَانِ ۝ وَالسَّمَاءَ رَفَعَهَا وَوَضَعَ الْمِيزَانَ ۝ أَلَّا تَطْغَوْا فِي الْمِيزَانِ ۝ وَأَقِيمُوا الْوَزْنَ بِالْقِسْطِ وَلَا تُخْسِرُوا الْمِيزَانَ ۝ وَالْأَرْضَ وَضَعَهَا لِلْأَنَامِ ۝ فِيهَا فَاكِهَةٌ وَالنَّخْلُ ذَاتُ الْأَكْمَامِ ۝ وَالْحَبُّ ذُو الْعَصْفِ وَالرَّيْحَانُ ۝ فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
        pronunciationBn: 'উচ্চারণ: আর-রহমা-ন। ‘আল্লামাল ক্বুরআ-ন। খলাক্বল ইনসা-ন। ‘আল্লামাহুল বায়া-ন। আশশামসু ওয়াল ক্বামারু বিহিসবা-ন। ওয়াননাজমু ওয়াশ শাজারু ইয়াসজুদা-ন। ওয়াসসামা-আ রফা‘আহা- ওয়া ওয়াদ্বা‘আল মীযা-ন... ফাবি আইয়্যি আ-লা-ই রব্বিকুমা তুকাজ্জিবা-ন।',
        meaningBn: 'অর্থ: পরম দয়াময় আল্লাহ। তিনি কোরআন শিক্ষা দিয়েছেন। তিনি মানব সৃষ্টি করেছেন। তাকে ভাব প্রকাশ শেখিয়েছেন। সূর্য ও চন্দ্র আবর্তন করে নির্ধারিত হিসেবে। আর তৃণলতা ও বৃক্ষরাজি সেজদারত রয়েছে। আকাশকে তিনি সমুন্নত করেছেন এবং স্থাপন করেছেন ভারসাম্য... অতএব, তোমরা উভয়ে তোমাদের রবের কোন কোন অনুগ্রহকে অস্বীকার করবে?',
        virtue: 'হাদিসে সূরা আর-রহমানকে কুরআনের বধূ (আরুসুল কুরআন) বলা হয়েছে। এটি পাঠে হৃদয়ে গভীর শান্তি আসে ও নিয়ামতের শোকর আদায় হয়।',
      ),
      SurahDuaEntity(
        id: ServerKey.keySuraYasin,
        titleBn: 'সূরা ইয়াসিন (কুরআনের হৃৎপিণ্ড)',
        titleAr: 'سورة يس',
        surahNumber: 'সূরা নং ৩৬ (মাক্কী, ৮৩ আয়াত)',
        arabicScript: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ يس ۝ وَالْقُرْآنِ الْحَكِيمِ ۝ إِنَّكَ لَمِنَ الْمُرْسَلِينَ ۝ عَلَىٰ صِرَاطٍ مُسْتَقِيمٍ ۝ تَنْزِيلَ الْعَزِيزِ الرَّحِيمِ ۝ لِتُنْذِرَ قَوْمًا مَا أُنْذِرَ آبَاؤُهُمْ فَهُمْ غَافِلُونَ ۝ لَقَدْ حَقَّ الْقَوْلُ عَلَىٰ أَكْثَرِهِمْ فَهُمْ لَا يُؤْمِنُونَ ۝ إِنَّا جَعَلْنَا فِي أَعْنَاقِهِمْ أَغْلَالًا فَهِيَ إِلَى الْأَذْقَانِ فَهُمْ مُقْمَحُونَ',
        pronunciationBn: 'উচ্চারণ: ইয়া-সীন। ওয়াল ক্বুরআ-নিল হাকীম। ইন্নাকা লামিনাল মুরসালীন। ‘আলা- সিরা-তিম মুস্তাক্বীম। তানযীলাল ‘আযীযির রহীম। লি তুনযিরা ক্বাওমাম মা- উনযিরা আ-বা-উহুম ফাহুম গ-ফিলূন...',
        meaningBn: 'অর্থ: ইয়াসীন। বিজ্ঞানময় কুরআনের শপথ। নিশ্চয়ই আপনি প্রেরিত রাসূলগণের অন্তর্ভুক্ত। সরল সোজা পথের ওপর প্রতিষ্ঠিত। এই কুরআন পরাক্রমশালী পরম দয়ালু আল্লাহর অবতীর্ণ, যাতে আপনি এমন এক জাতিকে সতর্ক করতে পারেন যাদের পূর্বপুরুষদের সতর্ক করা হয়নি...',
        virtue: 'রাসূলুল্লাহ (সা.) বলেছেন, \'সূরা ইয়াসিন কুরআনের হৃৎপিণ্ড। যে ব্যক্তি আল্লাহর সন্তুষ্টি ও পরকালের মুক্তির উদ্দেশ্যে এটি পাঠ করবে তার অতীত জীবনের গুনাহ ক্ষমা করে দেওয়া হবে।\'',
      ),
      SurahDuaEntity(
        id: ServerKey.keySuraMulk,
        titleBn: 'সূরা আল-মুলক (কবরের আজাব মুক্তি)',
        titleAr: 'سورة الملك',
        surahNumber: 'সূরা নং ৬৭ (মাক্কী, ৩০ আয়াত)',
        arabicScript: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ ۝ الَّذِي خَلَقَ الْمَوْتَ وَالْحَيَاةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا ۚ وَهُوَ الْعَزِيزُ الْغَفُورُ ۝ الَّذِي خَلَقَ سَبْعَ سَمَاوَاتٍ طِبَاقًا ۖ مَا تَرَىٰ فِي خَلْقِ الرَّحْمَٰنِ مِنْ تَفَاوُتٍ ۖ فَارْجِعِ الْبَصَرَ هَلْ تَرَىٰ مِنْ فُطُورٍ',
        pronunciationBn: 'উচ্চারণ: তাবা-রকাল্লাযী বিয়াদিহিল মুলকু ওয়াহুওয়া ‘আলা- কুল্লি শাইয়িন ক্বদীর। আল্লাযী খলাক্বল মাওতা ওয়াল হায়া-তা লিইয়াবলুওয়াকুম আইয়্যুকুম আহসানু ‘অমালা-, ওয়াহুওয়াল ‘আযীযুল গফূর। আল্লাযী খলাক্ব সাব‘আ সামা-ওয়া-তিন তিবা-ক্বা-...',
        meaningBn: 'অর্থ: বরকতময় তিনি যাঁর হাতে রয়েছে সার্বভৌম কর্তৃত্ব এবং তিনি সব কিছুর ওপর পূর্ণ ক্ষমতাবান। যিনি সৃষ্টি করেছেন মৃত্যু ও জীবন তোমাদের পরীক্ষা করার জন্য যে, কে তোমাদের মধ্যে আমলের দিক দিয়ে শ্রেষ্ঠ। আর তিনি পরাক্রমশালী, ক্ষমাশীল...',
        virtue: 'রাসূলুল্লাহ (সা.) বলেছেন, \'কুরআনে ত্রিশ আয়াতবিশিষ্ট একটি সূরা রয়েছে, যা পাঠকারীর জন্য সুপারিশ করতে থাকবে যতক্ষণ না তাকে ক্ষমা করে দেওয়া হয়; তা হলো সূরা তাবারাকাল্লাযী (আল-মুলক)।\' এটি কবরের আজাব থেকে রক্ষা করে।',
      ),
      SurahDuaEntity(
        id: ServerKey.keySuraKahaf,
        titleBn: 'সূরা আল-কাহাফ (জুমার বিশেষ নূর)',
        titleAr: 'سورة الكهف',
        surahNumber: 'সূরা নং ১৮ (মাক্কী, ১১০ আয়াত)',
        arabicScript: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ الَّذِي أَنْزَلَ عَلَىٰ عَبْدِهِ الْكِتَابَ وَلَمْ يَجْعَلْ لَهُ عِوَجًا ۝ قَيِّمًا لِيُنْذِرَ بَأْسًا شَدِيدًا مِنْ لَدُنْهُ وَيُبَشِّرَ الْمُؤْمِنِينَ الَّذِينَ يَعْمَلُونَ الصَّالِحَاتِ أَنَّ لَهُمْ أَجْرًا حَسَنًا ۝ مَاكِثِينَ فِيهِ أَبَدًا ۝ وَيُنْذِرَ الَّذِينَ قَالُوا اتَّخَذَ اللَّهُ وَلَدًا',
        pronunciationBn: 'উচ্চারণ: আলহামদু লিল্লা-হিল্লাযী আনযালা ‘আলা- ‘আবদিহিল কিতা-বা ওয়া লাম ইয়াজ‘আল লাহু ‘ইওয়াজা-। ক্বায়্যিমাল লিইউনযিরা বা’সান শাদীদাম মিল্লাদুনহু ওয়া ইউবাশশিরাল মু’মিনীনা...',
        meaningBn: 'অর্থ: যাবতীয় প্রশংসা আল্লাহর যিনি তাঁর বান্দার ওপর এই কিতাব অবতীর্ণ করেছেন এবং এতে কোনো বক্রতা রাখেননি। সুদৃঢ় বাণী, আল্লাহর পক্ষ থেকে এক কঠিন শাস্তি সম্পর্কে সতর্ক করার জন্য এবং সৎকর্মশীল মুমিনদের সুসংবাদ দেওয়ার জন্য...',
        virtue: 'রাসূলুল্লাহ (সা.) বলেছেন, \'যে ব্যক্তি জুমার দিনে সূরা কাহাফ পাঠ করবে, তার জন্য এক জুমা থেকে পরবর্তী জুমা পর্যন্ত বিশেষ নূর প্রজ্জ্বলিত থাকবে এবং দাজ্জালের ফিতনা হতে নিরাপদ থাকবে।\'',
      ),
      SurahDuaEntity(
        id: ServerKey.keyAyatulKursi,
        titleBn: 'আয়াতুল কুরসি (সূরা আল-বাকারা: ২৫৫)',
        titleAr: 'آية الكرسي',
        surahNumber: 'সূরা নং ২, আয়াত ২৫৫',
        arabicScript: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        pronunciationBn: 'উচ্চারণ: আল্লা-হু লা- ইলা-হা ইল্লা- হুওয়াল হাইয়্যুল ক্বাইয়্যূম। লা- তা’খুযুহু সিনাতুঁও ওয়ালা- নাওম। লাহূ মা- ফিসসামা-ওয়া-তি ওয়ামা- ফিল আরদ্ব। মান যাল্লাযী ইয়াশফা‘উ ‘ইনদাহূ ইল্লা- বিইযনিহী। ইয়া‘লামু মা- বাইনা আইদীহিম ওয়ামা- খলফাহুম...',
        meaningBn: 'অর্থ: আল্লাহ, তিনি ছাড়া কোনো সত্য উপাস্য নেই। তিনি চিরঞ্জীব, সবকিছুর ধারক। তন্দ্রা বা নিদ্রা তাঁকে স্পর্শ করে না। আকাশমণ্ডল ও পৃথিবীতে যা কিছু আছে সব তাঁরই...',
        virtue: 'কুরআনের সর্বশ্রেষ্ঠ আয়াত। ফরজ নামাজের পর পাঠকারী ও জান্নাতের মাঝে কেবল মৃত্যুই ব্যবধান থাকে। এটি শয়তানের অনিষ্ট ও সমস্ত আপদ-বিপদ হতে রক্ষাকারী ঢাল।',
      ),
    ];
  }

  /// Stream Super Global Quranic Surahs & Duas from Firestore
  Stream<List<SurahDuaEntity>> streamSurahsAndDuas() {
    try {
      final docRef = _firestore.collection(ServerKey.colSuperGlobal).doc(ServerKey.docSurahsDuas);
      return docRef.snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) {
          return getDefaultSurahsAndDuas();
        }
        final items = (snap.data()?['items'] as List?) ?? [];
        if (items.isEmpty) {
          return getDefaultSurahsAndDuas();
        }
        return items
            .map((m) => SurahDuaEntity.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }).handleError((e) {
        debugPrint('streamSurahsAndDuas error: $e');
        return getDefaultSurahsAndDuas();
      });
    } catch (e) {
      debugPrint('streamSurahsAndDuas init error: $e');
      return Stream.value(getDefaultSurahsAndDuas());
    }
  }

  /// Upload or update Super Global Surahs & Duas to Firebase Firestore
  Future<void> saveSuperGlobalSurahs(List<SurahDuaEntity> list) async {
    try {
      final docRef = _firestore.collection(ServerKey.colSuperGlobal).doc(ServerKey.docSurahsDuas);
      await docRef.set({
        'items': list.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Super Global Surahs and Duas saved to Firestore');
    } catch (e) {
      debugPrint('saveSuperGlobalSurahs error: $e');
    }
  }

  /// Automatically seeds all static Surahs, Duas, Amols, and Configs to Firestore on app startup
  /// if they do not exist or are empty on the server.
  Future<void> autoSeedSuperGlobalDefaults() async {
    try {
      // 1. Seed surahs_duas if missing or empty
      final surahDoc = _firestore.collection(ServerKey.colSuperGlobal).doc(ServerKey.docSurahsDuas);
      final surahSnap = await surahDoc.get();
      if (!surahSnap.exists ||
          surahSnap.data() == null ||
          (surahSnap.data()?['items'] as List?)?.isEmpty == true) {
        await surahDoc.set({
          'items': getDefaultSurahsAndDuas().map((s) => s.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Auto-seeded super_global/surahs_duas to Firestore successfully!');
      }

      // 2. Seed amol_templates if missing or empty
      final amolDoc = _firestore.collection(ServerKey.colSuperGlobal).doc(ServerKey.docAmolTemplates);
      final amolSnap = await amolDoc.get();
      if (!amolSnap.exists ||
          amolSnap.data() == null ||
          (amolSnap.data()?['items'] as List?)?.isEmpty == true) {
        await amolDoc.set({
          'items': getDefaultAmols().map((a) => a.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Auto-seeded super_global/amol_templates to Firestore successfully!');
      }

      // 3. Seed app_config/fcm_config template placeholder if missing
      final fcmDoc = _firestore.collection(ServerKey.colAppConfig).doc(ServerKey.docFcmConfig);
      final fcmSnap = await fcmDoc.get();
      if (!fcmSnap.exists) {
        await fcmDoc.set({
          'serverKey': '',
          'note': 'Paste Firebase Cloud Messaging Legacy Server Key here for remote push',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Initialized app_config/fcm_config template in Firestore!');
      }
    } catch (e) {
      debugPrint('autoSeedSuperGlobalDefaults error: $e');
    }
  }

  /// Add a new custom Surah or Dua directly to Firestore server
  Future<void> addNewSurahDua(SurahDuaEntity entity) async {
    try {
      final docRef = _firestore.collection(ServerKey.colSuperGlobal).doc(ServerKey.docSurahsDuas);
      await docRef.set({
        'items': FieldValue.arrayUnion([entity.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Added new Surah/Dua to Firestore: ${entity.titleBn}');
    } catch (e) {
      debugPrint('addNewSurahDua error: $e');
    }
  }
}

final amolTemplatesProvider = StreamProvider<List<AmolItem>>((ref) {
  return AmolService().streamAmolTemplates();
});

final surahsDuasProvider = StreamProvider<List<SurahDuaEntity>>((ref) {
  return AmolService().streamSurahsAndDuas();
});

