import 'package:flutter/services.dart';

class SoundService {
  static void playNotificationSound() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
