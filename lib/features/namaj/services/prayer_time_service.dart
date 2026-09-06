import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';

class PrayerTimeItem {
  final String id;
  final String nameBn;
  final String nameAr;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAlarmEnabled;
  final int reminderOffsetMinutes; // 0 = on time, 5 = 5 min before, etc.
  final String soundType; // 'adhan', 'high_sound', 'gentle_alarm', 'vibrate'

  const PrayerTimeItem({
    required this.id,
    required this.nameBn,
    required this.nameAr,
    required this.startTime,
    required this.endTime,
    this.isAlarmEnabled = true,
    this.reminderOffsetMinutes = 0,
    this.soundType = 'adhan',
  });

  PrayerTimeItem copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAlarmEnabled,
    int? reminderOffsetMinutes,
    String? soundType,
  }) {
    return PrayerTimeItem(
      id: id,
      nameBn: nameBn,
      nameAr: nameAr,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      soundType: soundType ?? this.soundType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'isAlarmEnabled': isAlarmEnabled ? 1 : 0,
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'soundType': soundType,
    };
  }
}

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Default standard prayer timings at server
  Map<String, dynamic> getDefaultServerTimings() {
    return {
      'fajr': {'startHour': 4, 'startMinute': 45, 'endHour': 5, 'endMinute': 58},
      'dhuhr': {'startHour': 12, 'startMinute': 5, 'endHour': 15, 'endMinute': 45},
      'asr': {'startHour': 15, 'startMinute': 45, 'endHour': 18, 'endMinute': 5},
      'maghrib': {'startHour': 18, 'startMinute': 5, 'endHour': 19, 'endMinute': 20},
      'isha': {'startHour': 19, 'startMinute': 20, 'endHour': 23, 'endMinute': 59},
    };
  }

  /// Stream server default prayer times from Firestore (app_config/default_prayer_times)
  Stream<Map<String, dynamic>> streamServerDefaultPrayerTimes() {
    try {
      final docRef = _firestore.collection('app_config').doc('default_prayer_times');
      return docRef.snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) {
          _seedDefaultServerPrayerTimes(docRef);
          return getDefaultServerTimings();
        }
        final timings = (snap.data()?['timings'] as Map<String, dynamic>?) ?? {};
        if (timings.isEmpty) {
          return getDefaultServerTimings();
        }
        return timings;
      }).handleError((e) {
        debugPrint('streamServerDefaultPrayerTimes error: $e');
        return getDefaultServerTimings();
      });
    } catch (e) {
      debugPrint('streamServerDefaultPrayerTimes init error: $e');
      return Stream.value(getDefaultServerTimings());
    }
  }

  Future<void> _seedDefaultServerPrayerTimes(DocumentReference docRef) async {
    try {
      await docRef.set({
        'timings': getDefaultServerTimings(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Seeded default server prayer timings to app_config/default_prayer_times');
    } catch (e) {
      debugPrint('Error seeding default prayer timings: $e');
    }
  }

  /// Combines server defaults with user-specific alarm & custom clock overrides
  List<PrayerTimeItem> getTodayPrayerTimes({
    Map<String, dynamic>? serverDefaults,
    Map<String, dynamic>? userAlarmSettings,
  }) {
    final defaults = serverDefaults != null && serverDefaults.isNotEmpty
        ? serverDefaults
        : getDefaultServerTimings();

    final fajrDef = defaults['fajr'] as Map<String, dynamic>? ?? {};
    final dhuhrDef = defaults['dhuhr'] as Map<String, dynamic>? ?? {};
    final asrDef = defaults['asr'] as Map<String, dynamic>? ?? {};
    final maghribDef = defaults['maghrib'] as Map<String, dynamic>? ?? {};
    final ishaDef = defaults['isha'] as Map<String, dynamic>? ?? {};

    final fajrUser = userAlarmSettings?['fajr'] as Map<String, dynamic>?;
    final dhuhrUser = userAlarmSettings?['dhuhr'] as Map<String, dynamic>?;
    final asrUser = userAlarmSettings?['asr'] as Map<String, dynamic>?;
    final maghribUser = userAlarmSettings?['maghrib'] as Map<String, dynamic>?;
    final ishaUser = userAlarmSettings?['isha'] as Map<String, dynamic>?;

    TimeOfDay parseTime(Map<String, dynamic>? userMap, Map<String, dynamic> defMap, String prefix) {
      if (userMap != null && userMap['${prefix}Hour'] != null && userMap['${prefix}Minute'] != null) {
        return TimeOfDay(
          hour: userMap['${prefix}Hour'] as int,
          minute: userMap['${prefix}Minute'] as int,
        );
      }
      return TimeOfDay(
        hour: (defMap['${prefix}Hour'] as int?) ?? 12,
        minute: (defMap['${prefix}Minute'] as int?) ?? 0,
      );
    }

    return [
      PrayerTimeItem(
        id: 'fajr',
        nameBn: 'ফজর',
        nameAr: 'الفجر',
        startTime: parseTime(fajrUser, fajrDef, 'start'),
        endTime: parseTime(fajrUser, fajrDef, 'end'),
        isAlarmEnabled: fajrUser?['isAlarmEnabled'] != 0 && fajrUser?['isAlarmEnabled'] != false,
        reminderOffsetMinutes: fajrUser?['reminderOffsetMinutes'] ?? 10,
        soundType: fajrUser?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'dhuhr',
        nameBn: 'যোহর',
        nameAr: 'الظهر',
        startTime: parseTime(dhuhrUser, dhuhrDef, 'start'),
        endTime: parseTime(dhuhrUser, dhuhrDef, 'end'),
        isAlarmEnabled: dhuhrUser?['isAlarmEnabled'] != 0 && dhuhrUser?['isAlarmEnabled'] != false,
        reminderOffsetMinutes: dhuhrUser?['reminderOffsetMinutes'] ?? 0,
        soundType: dhuhrUser?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'asr',
        nameBn: 'আসর',
        nameAr: 'العصر',
        startTime: parseTime(asrUser, asrDef, 'start'),
        endTime: parseTime(asrUser, asrDef, 'end'),
        isAlarmEnabled: asrUser?['isAlarmEnabled'] != 0 && asrUser?['isAlarmEnabled'] != false,
        reminderOffsetMinutes: asrUser?['reminderOffsetMinutes'] ?? 5,
        soundType: asrUser?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'maghrib',
        nameBn: 'মাগরিব',
        nameAr: 'المغرب',
        startTime: parseTime(maghribUser, maghribDef, 'start'),
        endTime: parseTime(maghribUser, maghribDef, 'end'),
        isAlarmEnabled: maghribUser?['isAlarmEnabled'] != 0 && maghribUser?['isAlarmEnabled'] != false,
        reminderOffsetMinutes: maghribUser?['reminderOffsetMinutes'] ?? 0,
        soundType: maghribUser?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'isha',
        nameBn: 'এশা ও তারাবীহ',
        nameAr: 'العشاء',
        startTime: parseTime(ishaUser, ishaDef, 'start'),
        endTime: parseTime(ishaUser, ishaDef, 'end'),
        isAlarmEnabled: ishaUser?['isAlarmEnabled'] != 0 && ishaUser?['isAlarmEnabled'] != false,
        reminderOffsetMinutes: ishaUser?['reminderOffsetMinutes'] ?? 0,
        soundType: ishaUser?['soundType'] ?? 'adhan',
      ),
    ];
  }

  /// Get currently active prayer or the upcoming one
  PrayerTimeItem? getCurrentOrNextPrayer(List<PrayerTimeItem> prayers) {
    if (prayers.isEmpty) return null;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final p in prayers) {
      final startMin = p.startTime.hour * 60 + p.startTime.minute;
      final endMin = p.endTime.hour * 60 + p.endTime.minute;
      if (nowMinutes >= startMin && nowMinutes <= endMin) {
        return p;
      }
    }
    // If before Fajr or after Isha
    return prayers.first;
  }

  /// Save user-specific prayer alarm settings to Firestore and SQLite
  /// This changes ONLY for this user; other users continue with server defaults or their own settings
  Future<void> savePrayerAlarmSettings({
    required String familyId,
    required String phone,
    required Map<String, dynamic> settings,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

    // 1. Save to SQLite cache
    try {
      final db = await AppDatabase().database;
      for (final entry in settings.entries) {
        final val = entry.value as Map<String, dynamic>;
        await db.insert(
          'prayer_alarms',
          {
            'waqtId': entry.key,
            'phoneNumber': cleanPhone,
            'isAlarmEnabled': (val['isAlarmEnabled'] == true || val['isAlarmEnabled'] == 1) ? 1 : 0,
            'reminderOffsetMinutes': val['reminderOffsetMinutes'] ?? 0,
            'soundType': val['soundType'] ?? 'adhan',
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}

    // 2. Save exclusively under this user's document
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('prayer_alarms')
          .doc(cleanPhone)
          .set({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Trigger feedback with high sound & strong vibration channel
      NotificationService().showPrayerAlarmNotification(
        id: 9991,
        title: 'নামাজের আযান ও অ্যালার্ম আপডেট',
        body: 'আপনার কাস্টম সময় ও অ্যালার্ম সফলভাবে নির্ধারিত হয়েছে।',
        soundType: 'high_sound',
      );
    } catch (e) {
      debugPrint('Firestore savePrayerAlarmSettings error: $e');
    }
  }

  /// Stream this specific user's prayer alarm settings from Firestore
  Stream<Map<String, dynamic>> streamPrayerAlarmSettings({
    required String familyId,
    required String phone,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('prayer_alarms')
        .doc(cleanPhone)
        .snapshots()
        .map((snap) => (snap.data()?['settings'] as Map<String, dynamic>?) ?? {});
  }
}
