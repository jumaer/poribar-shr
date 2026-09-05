import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class NetworkStateNotifier extends Notifier<NetworkStatus> {
  @override
  NetworkStatus build() => NetworkStatus.online;

  void setStatus(NetworkStatus status) {
    state = status;
  }

  void toggleStatus() {
    state = state == NetworkStatus.online ? NetworkStatus.offline : NetworkStatus.online;
  }
}

final networkStateProvider =
    NotifierProvider<NetworkStateNotifier, NetworkStatus>(
  NetworkStateNotifier.new,
);
