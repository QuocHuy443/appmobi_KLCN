import 'package:flutter/services.dart';

class SoundService {
  static Future<void> playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Sound/haptics may be unavailable on the current platform.
    }
  }
}
