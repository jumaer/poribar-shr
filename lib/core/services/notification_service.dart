import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

enum NotificationTabType { messages, offers, paymentsDue, activity }

class AppNotificationItem {
  final String id;
  final NotificationTabType tab;
  final String title;
  final String body;
  final String time;
  final String? senderName;
  final String? receiverId;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;

  const AppNotificationItem({
    required this.id,
    required this.tab,
    required this.title,
    required this.body,
    required this.time,
    this.senderName,
    this.receiverId,
    this.imageUrl,
    required this.icon,
    required this.iconColor,
  });
}

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotificationItem> _notifications = [];
  final StreamController<List<AppNotificationItem>> _controller =
      StreamController<List<AppNotificationItem>>.broadcast();

  final Map<String, DateTime> _recentPushCache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _familyNotifSub;
  String? _cachedFcmToken;
  bool _isInitialized = false;

  Stream<List<AppNotificationItem>> get notificationStream => _controller.stream;
  List<AppNotificationItem> get currentNotifications => List.unmodifiable(_notifications);
  String? get cachedFcmToken => _cachedFcmToken;

  /// Initializes runtime notification permissions and fetches FCM Token
  Future<void> initializeNotificationEngine({String? userIdOrPhone}) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Android 13+ (API 33+) & iOS runtime notification permission request
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      // Enable foreground display options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _cachedFcmToken = await messaging.getToken();
      debugPrint('Firebase FCM Token: $_cachedFcmToken');

      if (userIdOrPhone != null && userIdOrPhone.isNotEmpty && _cachedFcmToken != null) {
        await syncTokenToFirestore(userIdOrPhone, _cachedFcmToken!);
      }

      if (_isInitialized) return;
      _isInitialized = true;

      messaging.onTokenRefresh.listen((newToken) {
        _cachedFcmToken = newToken;
        if (userIdOrPhone != null && userIdOrPhone.isNotEmpty) {
          syncTokenToFirestore(userIdOrPhone, newToken);
        }
      });

      // Foreground notifications listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          final item = AppNotificationItem(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            tab: NotificationTabType.messages,
            title: notification.title ?? 'নতুন নোটিফিকেশন',
            body: notification.body ?? '',
            time: 'এখন',
            imageUrl: message.data['imageUrl'] ?? notification.android?.imageUrl,
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFF10B981),
          );
          _notifications.insert(0, item);
          _controller.add(List.unmodifiable(_notifications));
        }
      });
    } catch (e) {
      debugPrint('Notification engine init error: $e');
    }
  }

  /// Sync user device token to Firestore (both user doc and family member doc)
  Future<void> syncTokenToFirestore(String userPhoneOrUid, String token, {String? familyId}) async {
    try {
      final clean = userPhoneOrUid.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      await FirebaseFirestore.instance.collection('users').doc(clean).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync to active family member record if familyId is provided or can be fetched
      String targetFamilyId = familyId ?? '';
      if (targetFamilyId.isEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(clean).get();
        if (userDoc.exists && userDoc.data() != null) {
          targetFamilyId = userDoc.data()?['activeFamilyId']?.toString() ?? '';
        }
      }

      if (targetFamilyId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(targetFamilyId)
            .collection('members')
            .doc(clean)
            .set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('FCM Token synced to Firestore for $clean (Family: $targetFamilyId)');
    } catch (e) {
      debugPrint('Error syncing token to firestore: $e');
    }
  }

  /// Get active FCM tokens of other family members
  Future<List<String>> getOtherFamilyMemberTokens({
    required String familyId,
    required String excludePhone,
  }) async {
    try {
      final cleanExclude = excludePhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      final snap = await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('members')
          .get();
      final tokens = <String>[];
      for (final doc in snap.docs) {
        if (doc.id == cleanExclude) continue;
        final token = doc.data()['fcmToken']?.toString();
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      return tokens;
    } catch (e) {
      debugPrint('Error fetching family member tokens: $e');
      return [];
    }
  }

  /// Stream family notifications in real-time from Firestore
  void listenToFamilyNotifications(String familyId, {String? myPhone}) {
    if (familyId.isEmpty) return;
    final cleanMyPhone = myPhone?.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '') ?? '';
    _familyNotifSub?.cancel();
    _familyNotifSub = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = doc.id;
        final senderPhone = (data['senderPhone']?.toString() ?? data['memberPhone']?.toString() ?? '')
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('-', '');

        // If notification is a new_member alert for this user himself, skip it
        if (data['type'] == 'new_member' && cleanMyPhone.isNotEmpty && senderPhone == cleanMyPhone) {
          continue;
        }

        if (!_notifications.any((n) => n.id == id)) {
          final isMemberAlert = data['type'] == 'new_member';
          final isSos = data['type'] == 'sos_emergency';
          final isSentByMe = cleanMyPhone.isNotEmpty && senderPhone == cleanMyPhone;
          final img = data['imageUrl']?.toString();

          final title = isSos && isSentByMe
              ? '🚨 আপনি জরুরি সতর্কতা (SOS) পাঠিয়েছেন'
              : (data['title']?.toString() ?? 'পারিবারিক আপডেট');

          final body = isSos && isSentByMe
              ? 'পরিবার সদস্যদের কাছে আপনার জরুরি সংকেত ও অবস্থান পাঠানো হয়েছে।'
              : (data['body']?.toString() ?? '');

          final newItem = AppNotificationItem(
            id: id,
            tab: isMemberAlert ? NotificationTabType.activity : NotificationTabType.messages,
            title: title,
            body: body,
            time: 'এইমাত্র',
            senderName: isSentByMe
                ? 'আপনি'
                : (data['memberName']?.toString() ?? data['senderName']?.toString() ?? 'পরিবার সদস্য'),
            imageUrl: img,
            icon: isSos
                ? Icons.warning_amber_rounded
                : (isMemberAlert
                    ? Icons.person_add_alt_1_rounded
                    : (img != null ? Icons.image_outlined : Icons.notifications_active_outlined)),
            iconColor: isSos
                ? const Color(0xFFFF3B30)
                : (isMemberAlert ? const Color(0xFF30D158) : const Color(0xFF10B981)),
          );
          _notifications.insert(0, newItem);
        }
      }
      _controller.add(List.unmodifiable(_notifications));
    }, onError: (e) {
      debugPrint('Error listening to family notifications: $e');
    });
  }

  /// Broadcast new expense notification with image to family
  Future<void> broadcastExpenseEntryNotification({
    required String familyId,
    required String userName,
    required String purpose,
    required double amount,
    String? imageUrl,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'নতুন লেনদেন এন্ট্রি',
        'body': '$userName ৳ ${amount.toStringAsFixed(0)} টাকার "$purpose" হিসাব যুক্ত করেছেন।',
        'type': 'expense_entry',
        'memberName': userName,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      sendCustomPush(
        title: 'নতুন লেনদেন এন্ট্রি',
        body: '$userName: ৳ ${amount.toStringAsFixed(0)} ($purpose)',
        senderName: userName,
        receiverId: familyId,
        familyId: familyId,
        senderIsPermitted: true,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('broadcastExpenseEntryNotification error: $e');
    }
  }

  /// Broadcast celebratory salary notification with slip image to family
  Future<void> broadcastSalaryCreditNotification({
    required String familyId,
    required String userName,
    required double amount,
    String? imageUrl,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': '🎉 আলহামদুলিল্লাহ! মাসিক বেতন জমা হয়েছে!',
        'body': '$userName ৳ ${amount.toStringAsFixed(0)} টাকা বেতন হিসাবে জমা করেছেন। বরকত ও পারিবারিক কল্যাণের জন্য দোয়া রইল।',
        'type': 'salary_credit',
        'memberName': userName,
        'amount': amount,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      sendCustomPush(
        title: '🎉 আলহামদুলিল্লাহ! বেতন এসেছে: ৳ ${amount.toStringAsFixed(0)}',
        body: '$userName এর বেতন সফলভাবে জমা হয়েছে। রসিদ/স্লিপ দেখতে ট্যাপ করুন।',
        senderName: userName,
        receiverId: familyId,
        familyId: familyId,
        senderIsPermitted: true,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('broadcastSalaryCreditNotification error: $e');
    }
  }

  Future<void> sendCustomPush({
    required String title,
    required String body,
    required String senderName,
    required String receiverId,
    required bool senderIsPermitted,
    String? familyId,
    String? senderPhone,
    String? imageUrl,
  }) async {
    if (!senderIsPermitted) return;

    // Deduplication check: prevent identical push within 30 seconds
    final pushKey = '${familyId}_${title}_$body';
    final now = DateTime.now();
    _recentPushCache.removeWhere((_, time) => now.difference(time).inSeconds > 30);
    if (_recentPushCache.containsKey(pushKey)) {
      debugPrint('Skipping duplicate push within 30s: $pushKey');
      return;
    }
    _recentPushCache[pushKey] = now;

    final newItem = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tab: NotificationTabType.messages,
      title: title,
      body: body,
      time: 'এখন',
      senderName: senderName,
      receiverId: receiverId,
      imageUrl: imageUrl,
      icon: imageUrl != null ? Icons.image_outlined : Icons.notifications_active_outlined,
      iconColor: const Color(0xFF10B981),
    );

    _notifications.insert(0, newItem);
    _controller.add(List.unmodifiable(_notifications));

    // Save to Firestore notifications collection so other family devices receive it
    if (familyId != null && familyId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('notifications')
            .add({
          'title': title,
          'body': body,
          'type': 'custom_push',
          'senderName': senderName,
          'senderPhone': senderPhone,
          'receiverId': receiverId,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'time': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firestore write push notification error: $e');
      }
    }
  }

  void triggerAccessRevocationAlert({
    required String memberName,
    required String permissionType,
  }) {
    final alert = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tab: NotificationTabType.activity,
      title: 'পারমিশন পরিবর্তনের সতর্কতা',
      body: 'এডমিন $memberName এর $permissionType অনুমতি পরিবর্তন করেছেন',
      time: 'এইমাত্র',
      icon: Icons.security_update_warning_outlined,
      iconColor: const Color(0xFFE53935),
    );

    _notifications.insert(0, alert);
    _controller.add(List.unmodifiable(_notifications));
  }

  void scheduleExpenseReminderAlarm({
    required String title,
    required double amount,
    required DateTime dueDate,
  }) {
    final alarmNotif = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tab: NotificationTabType.paymentsDue,
      title: 'পরিশোধ অনুস্মারক: $title',
      body: '৳ ${amount.toStringAsFixed(0)} পরিশোধের শেষ তারিখ: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      time: 'নিয়মিত পুশ অ্যালার্ম',
      icon: Icons.alarm,
      iconColor: const Color(0xFFE53935),
    );

    _notifications.insert(0, alarmNotif);
    _controller.add(List.unmodifiable(_notifications));
  }

  /// Broadcast emergency SOS shake alert with location link to family
  Future<void> broadcastSosAlert({
    required String familyId,
    required String userName,
    required String userPhone,
    required double latitude,
    required double longitude,
    required String locationUrl,
  }) async {
    final title = '🚨 জরুরি সতর্কতা: বিপদে আছেন!';
    final body = '$userName বিপদে আছেন এবং জরুরি সাহায্য চেয়েছেন!\nবর্তমান অবস্থান: $locationUrl';

    // 1. Add to Firestore family notifications so all other members receive real-time alert
    if (familyId.isNotEmpty) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('notifications')
            .add({
          'title': title,
          'body': body,
          'type': 'sos_emergency',
          'senderName': userName,
          'senderPhone': userPhone,
          'latitude': latitude,
          'longitude': longitude,
          'locationUrl': locationUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'time': DateTime.now().toIso8601String(),
        });

        // Add local confirmation card using the same docRef ID so it never duplicates
        final localItem = AppNotificationItem(
          id: docRef.id,
          tab: NotificationTabType.messages,
          title: '🚨 আপনি জরুরি সতর্কতা (SOS) পাঠিয়েছেন',
          body: 'পরিবার সদস্যদের কাছে আপনার জরুরি সংকেত ও অবস্থান পাঠানো হয়েছে।\n$locationUrl',
          time: 'এইমাত্র',
          senderName: 'আপনি',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFFF3B30),
        );
        if (!_notifications.any((n) => n.id == docRef.id)) {
          _notifications.insert(0, localItem);
          _controller.add(List.unmodifiable(_notifications));
        }
      } catch (e) {
        debugPrint('Firestore broadcastSosAlert notifications error: $e');
      }

      // 3. Record in dedicated emergency sos_alerts collection
      try {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('sos_alerts')
            .add({
          'userName': userName,
          'userPhone': userPhone,
          'latitude': latitude,
          'longitude': longitude,
          'locationUrl': locationUrl,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore write sos_alerts error: $e');
      }
    }
  }
}
