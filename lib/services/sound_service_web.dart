import 'dart:js_interop';

@JS('AudioContext')
@staticInterop
class _AudioContext {
  external factory _AudioContext();
}

extension _AudioContextMethods on _AudioContext {
  external _Oscillator createOscillator();
  external _Gain createGain();
  external double get currentTime;
  external _AudioNode get destination;
  external JSPromise<JSAny?> resume();
  external JSPromise<JSAny?> close();
}

@JS()
@staticInterop
class _AudioParam {}

extension _AudioParamMethods on _AudioParam {
  external void setValueAtTime(double value, double time);
  external void exponentialRampToValueAtTime(double value, double time);
}

@JS()
@staticInterop
class _Oscillator implements _AudioNode {}

extension _OscillatorMethods on _Oscillator {
  external _AudioParam get frequency;
  external void connect(_AudioNode node);
  external void start(double time);
  external void stop(double time);
}

@JS()
@staticInterop
class _Gain implements _AudioNode {}

extension _GainMethods on _Gain {
  external _AudioParam get gain;
  external void connect(_AudioNode node);
}

@JS()
@staticInterop
class _AudioNode {}

class SoundService {
  static Future<void> playNotificationSound() async {
    _AudioContext? context;
    try {
      context = _AudioContext();
      // Browsers may block audio until the user interacts with the page.
      await context.resume().toDart.timeout(const Duration(seconds: 1));
      final oscillator = context.createOscillator();
      final gain = context.createGain();
      final now = context.currentTime;
      oscillator.frequency.setValueAtTime(659.25, now);
      oscillator.frequency.setValueAtTime(880, now + 0.12);
      gain.gain.setValueAtTime(0.25, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
      oscillator.connect(gain);
      gain.connect(context.destination);
      oscillator.start(now);
      oscillator.stop(now + 0.6);
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } catch (_) {
      // Audio is optional; a blocked sound must not affect notifications.
    } finally {
      try {
        await context?.close().toDart;
      } catch (_) {}
    }
  }
}
