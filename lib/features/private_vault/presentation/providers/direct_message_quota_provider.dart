import 'package:flutter_riverpod/flutter_riverpod.dart';

class DirectMessageQuotaNotifier extends Notifier<int> {
  static const int maxDailyLimit = 3;

  @override
  int build() => 1;

  bool get canSendMessage => state < maxDailyLimit;

  bool recordSentMessage() {
    if (canSendMessage) {
      state = state + 1;
      return true;
    }
    return false;
  }

  void resetQuota() {
    state = 0;
  }
}

final directMessageQuotaProvider =
    NotifierProvider<DirectMessageQuotaNotifier, int>(
  DirectMessageQuotaNotifier.new,
);
