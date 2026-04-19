import 'package:vibration/vibration.dart';

abstract interface class HapticsService {
  Future<void> playTaskScratchPattern();

  Future<void> playDismissThresholdTick();

  /// A light 'tick' for tapping bottom navigation tabs.
  Future<void> lightTick();

  /// A crisp, subtle click for the FAB and Priority toggles.
  Future<void> subtleClick();

  /// A 'Ramping' amplitude vibration for swiping/deleting a task card.
  Future<void> vibrateRamping();
}

class VibrationRequest {
  const VibrationRequest({
    this.duration = 500,
    this.pattern = const [],
    this.intensities = const [],
    this.amplitude = -1,
    this.sharpness = 0.5,
  });

  final int duration;
  final List<int> pattern;
  final List<int> intensities;
  final int amplitude;
  final double sharpness;

  int get totalDuration =>
      pattern.isEmpty ? duration : pattern.reduce((value, element) => value + element);
}

abstract interface class VibrationDriver {
  Future<bool> hasVibrator();

  Future<bool> hasAmplitudeControl();

  Future<bool> hasCustomVibrationsSupport();

  Future<void> vibrate(VibrationRequest request);
}

class PluginVibrationDriver implements VibrationDriver {
  const PluginVibrationDriver();

  @override
  Future<bool> hasAmplitudeControl() => Vibration.hasAmplitudeControl();

  @override
  Future<bool> hasCustomVibrationsSupport() =>
      Vibration.hasCustomVibrationsSupport();

  @override
  Future<bool> hasVibrator() => Vibration.hasVibrator();

  @override
  Future<void> vibrate(VibrationRequest request) {
    return Vibration.vibrate(
      duration: request.duration,
      pattern: request.pattern,
      intensities: request.intensities,
      amplitude: request.amplitude,
      sharpness: request.sharpness,
    );
  }
}

class DeviceHapticsService implements HapticsService {
  DeviceHapticsService({
    VibrationDriver? driver,
  }) : _driver = driver ?? const PluginVibrationDriver();

  static const List<int> _scratchPattern = [
    0,
    96,
    10,
    84,
    10,
    72,
    10,
    60,
    10,
    48,
    10,
    40,
  ];
  static const List<int> _scratchIntensities = [
    0,
    230,
    0,
    210,
    0,
    185,
    0,
    160,
    0,
    145,
    0,
    130,
  ];

  final VibrationDriver _driver;

  @override
  Future<void> playTaskScratchPattern() async {
    if (!await _driver.hasVibrator()) {
      return;
    }

    final hasAmplitudeControl = await _driver.hasAmplitudeControl();
    final hasCustomSupport = await _driver.hasCustomVibrationsSupport();

    if (hasCustomSupport) {
      await _driver.vibrate(
        VibrationRequest(
          pattern: _scratchPattern,
          intensities: hasAmplitudeControl ? _scratchIntensities : const [],
          sharpness: 0.85,
        ),
      );
      return;
    }

    await _driver.vibrate(
      const VibrationRequest(
        duration: 450,
        sharpness: 0.85,
      ),
    );
  }

  @override
  Future<void> playDismissThresholdTick() async {
    if (!await _driver.hasVibrator()) {
      return;
    }

    final hasAmplitudeControl = await _driver.hasAmplitudeControl();

    await _driver.vibrate(
      VibrationRequest(
        duration: 18,
        amplitude: hasAmplitudeControl ? 170 : -1,
        sharpness: 1,
      ),
    );
  }

  @override
  Future<void> lightTick() async {
    if (!await _driver.hasVibrator()) return;
    final hasAmplitude = await _driver.hasAmplitudeControl();
    await _driver.vibrate(
      VibrationRequest(
        duration: 12,
        amplitude: hasAmplitude ? 70 : -1,
        sharpness: 0.1,
      ),
    );
  }

  @override
  Future<void> subtleClick() async {
    if (!await _driver.hasVibrator()) return;
    final hasAmplitude = await _driver.hasAmplitudeControl();
    await _driver.vibrate(
      VibrationRequest(
        duration: 20,
        amplitude: hasAmplitude ? 150 : -1,
        sharpness: 0.7,
      ),
    );
  }

  @override
  Future<void> vibrateRamping() async {
    if (!await _driver.hasVibrator()) return;
    final hasAmplitude = await _driver.hasAmplitudeControl();
    if (hasAmplitude) {
      // Ramping effect: progressively increasing intensity
      await _driver.vibrate(
        VibrationRequest(
          pattern: [0, 40, 40, 40, 40, 40],
          intensities: [0, 40, 80, 130, 190, 255],
          sharpness: 0.5,
        ),
      );
    } else {
      await _driver.vibrate(const VibrationRequest(duration: 200));
    }
  }
}
