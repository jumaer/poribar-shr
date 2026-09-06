import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'notification_service.dart';

class SosTriggerEvent {
  final String userName;
  final String userPhone;
  final double? latitude;
  final double? longitude;
  final String locationUrl;
  final DateTime time;
  final bool isLocationAcquired;

  const SosTriggerEvent({
    required this.userName,
    required this.userPhone,
    this.latitude,
    this.longitude,
    required this.locationUrl,
    required this.time,
    required this.isLocationAcquired,
  });
}

class SosShakeService {
  static final SosShakeService _instance = SosShakeService._internal();
  factory SosShakeService() => _instance;
  SosShakeService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  final StreamController<SosTriggerEvent> _triggerController =
      StreamController<SosTriggerEvent>.broadcast();

  bool _isEnabled = true;
  bool _isProcessingSos = false;
  DateTime? _lastShakeTimestamp;
  int _shakeCount = 0;

  // Sensitivity settings
  static const double _shakeThreshold = 18.0; // Acceleration magnitude in m/s^2
  static const int _shakeCountRequired = 3;   // Shakes needed within time window
  static const Duration _shakeWindow = Duration(milliseconds: 1400);
  static const Duration _cooldown = Duration(seconds: 10);
  DateTime? _lastSosTriggeredTime;

  Stream<SosTriggerEvent> get onSosTriggered => _triggerController.stream;
  bool get isEnabled => _isEnabled;
  bool get isProcessingSos => _isProcessingSos;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Start listening to device shake motion
  void startListening({
    required String familyId,
    required String userName,
    required String userPhone,
  }) {
    _accelerometerSub?.cancel();

    _accelerometerSub = userAccelerometerEventStream().listen(
      (UserAccelerometerEvent event) {
        if (!_isEnabled || _isProcessingSos) return;

        // Check cooldown window to prevent duplicate triggers
        if (_lastSosTriggeredTime != null &&
            DateTime.now().difference(_lastSosTriggeredTime!) < _cooldown) {
          return;
        }

        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

        if (magnitude > _shakeThreshold) {
          final now = DateTime.now();
          if (_lastShakeTimestamp == null ||
              now.difference(_lastShakeTimestamp!) > _shakeWindow) {
            _shakeCount = 1;
            _lastShakeTimestamp = now;
          } else {
            _shakeCount++;
            _lastShakeTimestamp = now;
            if (_shakeCount >= _shakeCountRequired) {
              _shakeCount = 0;
              _lastSosTriggeredTime = now;
              triggerEmergencySos(
                familyId: familyId,
                userName: userName,
                userPhone: userPhone,
              );
            }
          }
        }
      },
      onError: (e) {
        debugPrint('SosShakeService accelerometer stream error: $e');
      },
    );
  }

  /// Stop listening to device shake
  void stopListening() {
    _accelerometerSub?.cancel();
    _accelerometerSub = null;
  }

  /// Request location permission explicitly
  Future<bool> checkAndRequestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Triggers the full SOS emergency process:
  /// 1. Heavy haptic alert
  /// 2. Acquire current GPS coordinates
  /// 3. Create Google Maps URL
  /// 4. Broadcast via Firebase & NotificationService
  /// 5. Emit event for UI dialog
  Future<SosTriggerEvent> triggerEmergencySos({
    required String familyId,
    required String userName,
    required String userPhone,
  }) async {
    _isProcessingSos = true;

    // 1. Immediate heavy haptic alert to confirm detection
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 180), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 360), () => HapticFeedback.heavyImpact());
    } catch (_) {}

    double? lat;
    double? lng;
    String locationUrl = 'অবস্থান সংগ্রহ করা যায়নি';
    bool locationAcquired = false;

    // 2. Fetch GPS Position
    try {
      final hasPermission = await checkAndRequestLocationPermission();
      if (hasPermission) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          // Fallback to last known position
          position = await Geolocator.getLastKnownPosition();
        }

        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
          locationUrl = 'https://maps.google.com/?q=$lat,$lng';
          locationAcquired = true;
        }
      }
    } catch (e) {
      debugPrint('SosShakeService GPS acquisition error: $e');
    }

    // 3. Broadcast to Family via Firebase Notification Service
    await NotificationService().broadcastSosAlert(
      familyId: familyId,
      userName: userName,
      userPhone: userPhone,
      latitude: lat ?? 0.0,
      longitude: lng ?? 0.0,
      locationUrl: locationUrl,
    );

    final event = SosTriggerEvent(
      userName: userName,
      userPhone: userPhone,
      latitude: lat,
      longitude: lng,
      locationUrl: locationUrl,
      time: DateTime.now(),
      isLocationAcquired: locationAcquired,
    );

    _triggerController.add(event);
    _isProcessingSos = false;

    return event;
  }
}
