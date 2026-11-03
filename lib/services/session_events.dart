import 'package:flutter/foundation.dart';

class SessionRejection {
  const SessionRejection(this.token, this.profileRequired);
  final String token;
  final bool profileRequired;
}

class SessionEvents {
  static final rejected = ValueNotifier<SessionRejection?>(null);
  static void reject(String token, {bool profileRequired = false}) {
    rejected.value = SessionRejection(token, profileRequired);
  }
}
