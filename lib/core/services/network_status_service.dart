import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusService {
  static final NetworkStatusService _instance = NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void startMonitoring() {
    _checkStatus();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  Future<bool> checkConnection() async {
    return await _checkStatus();
  }

  Future<bool> _checkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (_isOnline != connected) {
        _isOnline = connected;
        _controller.add(_isOnline);
      }
      return connected;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('1.1.1.1')
            .timeout(const Duration(seconds: 3));
        final connected = fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
        if (_isOnline != connected) {
          _isOnline = connected;
          _controller.add(_isOnline);
        }
        return connected;
      } catch (e) {
        if (_isOnline != false) {
          _isOnline = false;
          _controller.add(false);
        }
        return false;
      }
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
  }
}

class NetworkStatusNotifier extends Notifier<bool> {
  StreamSubscription<bool>? _subscription;

  @override
  bool build() {
    final service = NetworkStatusService();
    service.startMonitoring();
    _subscription?.cancel();
    _subscription = service.onConnectivityChanged.listen((online) {
      state = online;
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return service.isOnline;
  }

  Future<void> refresh() async {
    final isConnected = await NetworkStatusService().checkConnection();
    state = isConnected;
  }
}

final networkStatusProvider = NotifierProvider<NetworkStatusNotifier, bool>(
  NetworkStatusNotifier.new,
);
