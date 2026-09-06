import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../features/notifications/presentation/screens/notification_screen.dart';

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
  debugPrint('FCM Background/Terminated message received: ${message.messageId}');
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'SRH পারিবারিক নোটিফিকেশন';
  final body = notification?.body ?? message.data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    try {
      final localNotif = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await localNotif.initialize(settings: initSettings);

      const androidDetails = AndroidNotificationDetails(
        'srh_family_channel',
        'SRH পারিবারিক নোটিফিকেশন',
        channelDescription: 'জরুরি সতর্কতা, আয়-ব্যয়, ঋণ ও পারিবারিক আপডেট',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await localNotif.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'NOTIFICATION_CLICK',
      );
    } catch (e) {
      debugPrint('Background notification display error: $e');
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final List<AppNotificationItem> _notifications = [];
  final StreamController<List<AppNotificationItem>> _controller =
      StreamController<List<AppNotificationItem>>.broadcast();

  final Map<String, DateTime> _recentPushCache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _familyNotifSub;
  String? _cachedFcmToken;
  String? _currentUserPhone;
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  Stream<List<AppNotificationItem>> get notificationStream => _controller.stream;
  List<AppNotificationItem> get currentNotifications => List.unmodifiable(_notifications);
  String? get cachedFcmToken => _cachedFcmToken;

  /// Setup click handler to open notification screen when notification is tapped
  void setupNotificationClickHandlers(GlobalKey<NavigatorState> navKey) {
    _navigatorKey = navKey;

    // 1. Terminated state launch
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from terminated state via push notification');
        _handleNotificationClick(message.data);
      }
    });

    // 2. Background state click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background state via push notification');
      _handleNotificationClick(message.data);
    });
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('Notification clicked! Navigating to NotificationScreen...');
    final nav = _navigatorKey?.currentState;
    if (nav != null) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    }
  }

  /// Initializes runtime notification permissions, FlutterLocalNotifications, and fetches FCM Token
  Future<void> initializeNotificationEngine({String? userIdOrPhone}) async {
    try {
      if (userIdOrPhone != null && userIdOrPhone.isNotEmpty) {
        _currentUserPhone = userIdOrPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      }

      // 1. Setup Flutter Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationClick({'payload': response.payload});
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Standard Family Push Channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'srh_family_channel',
            'SRH পারিবারিক নোটিফিকেশন',
            description: 'জরুরি সতর্কতা, আয়-ব্যয়, ঋণ ও পারিবারিক আপডেট',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        // High Sound & Strong Vibration Prayer Alarm Channel
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'srh_prayer_alarm_channel',
            'নামাজের আযান ও অ্যালার্ম',
            description: 'ওয়াক্ত আযান, উচ্চ শব্দ এবং ভাইব্রেশন সহ অ্যালার্ম',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
          ),
        );
      }

      final messaging = FirebaseMessaging.instance;

      // 2. Android 13+ & iOS runtime notification permission request
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      // Crucial: Suppress system notification alert popups when the app is in the FOREGROUND
      // Pushes will only show as OS alerts in BACKGROUND and TERMINATED states.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
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

      // Foreground notifications listener:
      // Updates in-app state only; does NOT trigger system popups.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'];
        final body = notification?.body ?? message.data['body'];
        final senderPhone = (message.data['senderPhone']?.toString() ?? '')
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('-', '');

        // Never show push for sender's own actions
        if (_currentUserPhone != null &&
            _currentUserPhone!.isNotEmpty &&
            senderPhone == _currentUserPhone) {
          return;
        }

        if (title != null || body != null) {
          final item = AppNotificationItem(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            tab: NotificationTabType.messages,
            title: title ?? 'নতুন নোটিফিকেশন',
            body: body ?? '',
            time: 'এখন',
            imageUrl: message.data['imageUrl'] ?? notification?.android?.imageUrl,
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

  /// Show a real system tray / heads-up notification on the device
  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'srh_family_channel',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'srh_prayer_alarm_channel' ? 'নামাজের আযান ও অ্যালার্ম' : 'SRH পারিবারিক নোটিফিকেশন',
        channelDescription: 'জরুরি সতর্কতা, আয়-ব্যয়, ঋণ ও পারিবারিক আপডেট',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      final notifId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload ?? 'NOTIFICATION_CLICK',
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Show high sound and strong vibration prayer alarm notification
  Future<void> showPrayerAlarmNotification({
    required int id,
    required String title,
    required String body,
    String? soundType,
  }) async {
    try {
      final isVibrateOnly = soundType == 'vibrate';

      final androidDetails = AndroidNotificationDetails(
        'srh_prayer_alarm_channel',
        'নামাজের আযান ও অ্যালার্ম',
        channelDescription: 'ওয়াক্ত আযান, উচ্চ শব্দ এবং ভাইব্রেশন সহ অ্যালার্ম',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
        playSound: !isVibrateOnly,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'PRAYER_ALARM_CLICK',
      );
    } catch (e) {
      debugPrint('Error showing prayer alarm notification: $e');
    }
  }

  /// Sync user device token to Firestore (both user doc and family member doc)
  Future<void> syncTokenToFirestore(String userPhoneOrUid, String token, {String? familyId}) async {
    try {
      final clean = userPhoneOrUid.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      _currentUserPhone = clean;
      await FirebaseFirestore.instance.collection('users').doc(clean).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

        // Subscribe to family topic so broadcast messages reach devices
        try {
          final cleanFamily = targetFamilyId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
          await FirebaseMessaging.instance.subscribeToTopic('family_$cleanFamily');
        } catch (_) {}
      }
      debugPrint('FCM Token synced to Firestore for $clean (Family: $targetFamilyId)');
    } catch (e) {
      debugPrint('Error syncing token to firestore: $e');
    }
  }

  /// Get active FCM tokens of other family members (strictly excludes the sender)
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
        if (token != null && token.isNotEmpty && !tokens.contains(token)) {
          tokens.add(token);
        }
      }
      return tokens;
    } catch (e) {
      debugPrint('Error fetching family member tokens: $e');
      return [];
    }
  }

  /// Send real FCM notification via HTTP to destination tokens so terminated & background apps receive it
  Future<void> sendFcmNotificationToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    String? senderName,
    String? senderPhone,
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) async {
    if (tokens.isEmpty) return;
    try {
      // Fetch server key from app_config/fcm_config if available
      String? serverKey;
      try {
        final configDoc =
            await FirebaseFirestore.instance.collection('app_config').doc('fcm_config').get();
        if (configDoc.exists && configDoc.data() != null) {
          serverKey = configDoc.data()?['serverKey']?.toString();
        }
      } catch (_) {}

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (serverKey != null && serverKey.isNotEmpty) {
        headers['Authorization'] = 'key=$serverKey';
      }

      final payload = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': body,
          'android_channel_id': 'srh_family_channel',
          'sound': 'default',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          'title': title,
          'body': body,
          'senderName': senderName ?? '',
          'senderPhone': senderPhone ?? '',
          'imageUrl': imageUrl ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          ...?extraData,
        },
        'priority': 'high',
      };

      if (serverKey != null && serverKey.isNotEmpty) {
        final res = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: headers,
          body: jsonEncode(payload),
        );
        debugPrint('FCM Push send response: ${res.statusCode} - ${res.body}');
      } else {
        debugPrint('FCM Server key not configured in Firestore app_config/fcm_config. Saved to Firestore.');
      }
    } catch (e) {
      debugPrint('sendFcmNotificationToTokens error: $e');
    }
  }

  /// Stream family notifications in real-time from Firestore
  void listenToFamilyNotifications(String familyId, {String? myPhone}) {
    if (familyId.isEmpty) return;
    final cleanMyPhone = myPhone?.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '') ?? '';
    if (cleanMyPhone.isNotEmpty) {
      _currentUserPhone = cleanMyPhone;
    }

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
        final receiverRaw = data['receiverId']?.toString();
        final receiverId = receiverRaw?.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

        final isSentByMe = cleanMyPhone.isNotEmpty && senderPhone == cleanMyPhone;

        // Rule 1: NEVER send or show incoming notifications to the sender himself
        if (isSentByMe && data['type'] != 'sos_emergency') {
          continue;
        }

        // Rule 2: If targeted to a specific receiver (not 'all' or empty), ignore if not for this user
        if (receiverId != null &&
            receiverId.isNotEmpty &&
            receiverId != 'all' &&
            !receiverId.contains('সবাই') &&
            receiverId != cleanMyPhone) {
          continue;
        }

        if (!_notifications.any((n) => n.id == id)) {
          final isMemberAlert = data['type'] == 'new_member';
          final isSos = data['type'] == 'sos_emergency';
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

          // NOTE: Per requirement, when the app is OPEN in FOREGROUND, DO NOT display system push popups.
          // In-app list is updated automatically.
        }
      }
      _controller.add(List.unmodifiable(_notifications));
    }, onError: (e) {
      debugPrint('Error listening to family notifications: $e');
    });
  }

  /// Broadcast new expense notification to other family members
  Future<void> broadcastExpenseEntryNotification({
    required String familyId,
    required String userName,
    required String purpose,
    required double amount,
    String? imageUrl,
  }) async {
    try {
      final senderPhone = _currentUserPhone ?? '';
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'নতুন লেনদেন এন্ট্রি',
        'body': '$userName ৳ ${amount.toStringAsFixed(0)} টাকার "$purpose" হিসাব যুক্ত করেছেন।',
        'type': 'expense_entry',
        'memberName': userName,
        'senderPhone': senderPhone,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      // Send FCM push to all other members (strictly excluding sender)
      final tokens = await getOtherFamilyMemberTokens(
        familyId: familyId,
        excludePhone: senderPhone,
      );

      await sendFcmNotificationToTokens(
        tokens: tokens,
        title: 'নতুন লেনদেন এন্ট্রি',
        body: '$userName: ৳ ${amount.toStringAsFixed(0)} ($purpose)',
        senderName: userName,
        senderPhone: senderPhone,
        imageUrl: imageUrl,
        extraData: {'familyId': familyId, 'type': 'expense_entry'},
      );
    } catch (e) {
      debugPrint('broadcastExpenseEntryNotification error: $e');
    }
  }

  /// Broadcast celebratory salary notification to other family members
  Future<void> broadcastSalaryCreditNotification({
    required String familyId,
    required String userName,
    required double amount,
    String? imageUrl,
  }) async {
    try {
      final senderPhone = _currentUserPhone ?? '';
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': '🎉 আলহামদুলিল্লাহ! মাসিক বেতন জমা হয়েছে!',
        'body': '$userName ৳ ${amount.toStringAsFixed(0)} টাকা বেতন হিসাবে জমা করেছেন। বরকত ও পারিবারিক কল্যাণের জন্য দোয়া রইল।',
        'type': 'salary_credit',
        'memberName': userName,
        'senderPhone': senderPhone,
        'amount': amount,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      // Send FCM push to all other members (strictly excluding sender)
      final tokens = await getOtherFamilyMemberTokens(
        familyId: familyId,
        excludePhone: senderPhone,
      );

      await sendFcmNotificationToTokens(
        tokens: tokens,
        title: '🎉 আলহামদুলিল্লাহ! বেতন এসেছে: ৳ ${amount.toStringAsFixed(0)}',
        body: '$userName এর বেতন সফলভাবে জমা হয়েছে। রসিদ/স্লিপ দেখতে ট্যাপ করুন।',
        senderName: userName,
        senderPhone: senderPhone,
        imageUrl: imageUrl,
        extraData: {'familyId': familyId, 'type': 'salary_credit'},
      );
    } catch (e) {
      debugPrint('broadcastSalaryCreditNotification error: $e');
    }
  }

  /// Send custom push notification from admin to target members
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

    final cleanSender = (senderPhone ?? _currentUserPhone ?? '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('-', '');

    // Deduplication check: prevent identical push within 30 seconds
    final pushKey = '${familyId}_${title}_$body';
    final now = DateTime.now();
    _recentPushCache.removeWhere((_, time) => now.difference(time).inSeconds > 30);
    if (_recentPushCache.containsKey(pushKey)) {
      debugPrint('Skipping duplicate push within 30s: $pushKey');
      return;
    }
    _recentPushCache[pushKey] = now;

    // Save to Firestore notifications collection so others receive it
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
          'senderPhone': cleanSender,
          'receiverId': receiverId,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'time': DateTime.now().toIso8601String(),
        });

        // 1. Collect target FCM tokens (excluding sender)
        List<String> targetTokens = [];
        final isAll = receiverId.isEmpty || receiverId.contains('সবাই') || receiverId == 'all';

        if (isAll) {
          targetTokens = await getOtherFamilyMemberTokens(
            familyId: familyId,
            excludePhone: cleanSender,
          );
        } else {
          final cleanReceiver = receiverId.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
          // Do not send to self if sender selected their own name
          if (cleanReceiver != cleanSender) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(cleanReceiver)
                .get();
            final token = userDoc.data()?['fcmToken']?.toString();
            if (token != null && token.isNotEmpty) {
              targetTokens.add(token);
            }
          }
        }

        // 2. Dispatch FCM Push so it arrives when app is terminated or in background
        if (targetTokens.isNotEmpty) {
          await sendFcmNotificationToTokens(
            tokens: targetTokens,
            title: title,
            body: body,
            senderName: senderName,
            senderPhone: cleanSender,
            imageUrl: imageUrl,
            extraData: {'familyId': familyId, 'type': 'custom_push'},
          );
        }
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

  /// Broadcast emergency SOS shake alert with location link to other family members
  Future<void> broadcastSosAlert({
    required String familyId,
    required String userName,
    required String userPhone,
    required double latitude,
    required double longitude,
    required String locationUrl,
  }) async {
    final title = '🚨 জরুরি সতর্কতা: বিপদে আছেন!';
    final body = '$userName বিপদে আছেন এবং জরুরি সাহায্য চেয়েছেন!\nবর্তমান অবস্থান: $locationUrl';
    final cleanSender = userPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

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
          'senderPhone': cleanSender,
          'latitude': latitude,
          'longitude': longitude,
          'locationUrl': locationUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'time': DateTime.now().toIso8601String(),
        });

        // Add local confirmation card for the sender
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

        // Dispatch FCM push to other family members
        final tokens = await getOtherFamilyMemberTokens(
          familyId: familyId,
          excludePhone: cleanSender,
        );
        await sendFcmNotificationToTokens(
          tokens: tokens,
          title: title,
          body: body,
          senderName: userName,
          senderPhone: cleanSender,
          extraData: {
            'familyId': familyId,
            'type': 'sos_emergency',
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'locationUrl': locationUrl,
          },
        );
      } catch (e) {
        debugPrint('Firestore broadcastSosAlert notifications error: $e');
      }

      // Record in dedicated emergency sos_alerts collection
      try {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('sos_alerts')
            .add({
          'userName': userName,
          'userPhone': cleanSender,
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
