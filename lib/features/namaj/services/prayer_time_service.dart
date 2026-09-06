import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';

class PrayerTimeItem {
  final String id;
  final String nameBn;
  final String nameAr;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAlarmEnabled;
  final int reminderOffsetMinutes; // 0 = on time, 5 = 5 min before, etc.
  final String soundType; // 'adhan', 'gentle_alarm', 'vibrate'

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
    bool? isAlarmEnabled,
    int? reminderOffsetMinutes,
    String? soundType,
  }) {
    return PrayerTimeItem(
      id: id,
      nameBn: nameBn,
      nameAr: nameAr,
      startTime: startTime,
      endTime: endTime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      soundType: soundType ?? this.soundType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  /// Calculates prayer times based on the current date for Bangladesh standard timezone (BST)
  List<PrayerTimeItem> getTodayPrayerTimes({
    Map<String, dynamic>? alarmSettings,
  }) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Seasonal variance calculation (minutes offset based on day of year)
    final double seasonalShift = (dayOfYear - 80) * 0.15;
    final int shiftMinutes = seasonalShift.clamp(-20, 20).toInt();

    final fajrHour = 4;
    final fajrMin = (45 - (shiftMinutes ~/ 2)).clamp(10, 59);

    final sunriseHour = 5;
    final sunriseMin = (58 - (shiftMinutes ~/ 2)).clamp(10, 59);

    final dhuhrHour = 12;
    final dhuhrMin = 1 + (shiftMinutes ~/ 4);

    final asrHour = 15;
    final asrMin = (45 + (shiftMinutes ~/ 3)).clamp(15, 59);

    final maghribHour = 18;
    final maghribMin = (5 + shiftMinutes).clamp(5, 59);

    final ishaHour = 19;
    final ishaMin = (20 + shiftMinutes).clamp(15, 59);

    final fajrSetting = alarmSettings?['fajr'] as Map<String, dynamic>?;
    final dhuhrSetting = alarmSettings?['dhuhr'] as Map<String, dynamic>?;
    final asrSetting = alarmSettings?['asr'] as Map<String, dynamic>?;
    final maghribSetting = alarmSettings?['maghrib'] as Map<String, dynamic>?;
    final ishaSetting = alarmSettings?['isha'] as Map<String, dynamic>?;

    return [
      PrayerTimeItem(
        id: 'fajr',
        nameBn: 'ফজর',
        nameAr: 'الفجر',
        startTime: TimeOfDay(hour: fajrHour, minute: fajrMin),
        endTime: TimeOfDay(hour: sunriseHour, minute: sunriseMin),
        isAlarmEnabled: fajrSetting?['isAlarmEnabled'] != 0,
        reminderOffsetMinutes: fajrSetting?['reminderOffsetMinutes'] ?? 10,
        soundType: fajrSetting?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'dhuhr',
        nameBn: 'যোহর',
        nameAr: 'الظهر',
        startTime: TimeOfDay(hour: dhuhrHour, minute: dhuhrMin),
        endTime: TimeOfDay(hour: asrHour, minute: asrMin),
        isAlarmEnabled: dhuhrSetting?['isAlarmEnabled'] != 0,
        reminderOffsetMinutes: dhuhrSetting?['reminderOffsetMinutes'] ?? 0,
        soundType: dhuhrSetting?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'asr',
        nameBn: 'আসর',
        nameAr: 'العصر',
        startTime: TimeOfDay(hour: asrHour, minute: asrMin),
        endTime: TimeOfDay(hour: maghribHour, minute: maghribMin),
        isAlarmEnabled: asrSetting?['isAlarmEnabled'] != 0,
        reminderOffsetMinutes: asrSetting?['reminderOffsetMinutes'] ?? 5,
        soundType: asrSetting?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'maghrib',
        nameBn: 'মাগরিব',
        nameAr: 'المغرب',
        startTime: TimeOfDay(hour: maghribHour, minute: maghribMin),
        endTime: TimeOfDay(hour: ishaHour, minute: ishaMin),
        isAlarmEnabled: maghribSetting?['isAlarmEnabled'] != 0,
        reminderOffsetMinutes: maghribSetting?['reminderOffsetMinutes'] ?? 0,
        soundType: maghribSetting?['soundType'] ?? 'adhan',
      ),
      PrayerTimeItem(
        id: 'isha',
        nameBn: 'এশা ও তারাবীহ',
        nameAr: 'العشاء',
        startTime: TimeOfDay(hour: ishaHour, minute: ishaMin),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        isAlarmEnabled: ishaSetting?['isAlarmEnabled'] != 0,
        reminderOffsetMinutes: ishaSetting?['reminderOffsetMinutes'] ?? 0,
        soundType: ishaSetting?['soundType'] ?? 'adhan',
      ),
    ];
  }

  /// Get currently active prayer or the upcoming one
  PrayerTimeItem? getCurrentOrNextPrayer(List<PrayerTimeItem> prayers) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final p in prayers) {
      final startMin = p.startTime.hour * 60 + p.startTime.minute;
      final endMin = p.endTime.hour * 60 + p.endTime.minute;
      if (nowMinutes >= startMin && nowMinutes <= endMin) {
        return p;
      }
    }
    // If night before Fajr
    return prayers.first;
  }

  /// Save prayer alarm settings to Firestore and SQLite
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
            'isAlarmEnabled': val['isAlarmEnabled'] == true ? 1 : 0,
            'reminderOffsetMinutes': val['reminderOffsetMinutes'] ?? 0,
            'soundType': val['soundType'] ?? 'adhan',
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}

    // 2. Save to Firestore
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
    } catch (e) {
      debugPrint('Firestore savePrayerAlarmSettings error: $e');
    }
  }

  /// Stream prayer alarm settings from Firestore
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
