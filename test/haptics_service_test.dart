import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/services/haptics_service.dart';

class FakeVibrationDriver implements VibrationDriver {
  FakeVibrationDriver({
    this.hasVibratorValue = true,
    this.hasAmplitudeControlValue = true,
    this.hasCustomSupportValue = true,
  });

  final bool hasVibratorValue;
  final bool hasAmplitudeControlValue;
  final bool hasCustomSupportValue;
  final List<VibrationRequest> calls = [];

  @override
  Future<bool> hasAmplitudeControl() async => hasAmplitudeControlValue;

  @override
  Future<bool> hasCustomVibrationsSupport() async => hasCustomSupportValue;

  @override
  Future<bool> hasVibrator() async => hasVibratorValue;

  @override
  Future<void> vibrate(VibrationRequest request) async {
    calls.add(request);
  }
}

void main() {
  group('DeviceHapticsService', () {
    test('uses a tapered scratch waveform that matches the animation duration', () async {
      final driver = FakeVibrationDriver();
      final service = DeviceHapticsService(driver: driver);

      await service.playTaskScratchPattern();

      expect(driver.calls, hasLength(1));
      expect(driver.calls.single.pattern, [0, 96, 10, 84, 10, 72, 10, 60, 10, 48, 10, 40]);
      expect(driver.calls.single.intensities, [0, 230, 0, 210, 0, 185, 0, 160, 0, 145, 0, 130]);
      expect(driver.calls.single.totalDuration, 450);
    });

    test('uses a single sharp tick when the dismiss threshold is reached', () async {
      final driver = FakeVibrationDriver();
      final service = DeviceHapticsService(driver: driver);

      await service.playDismissThresholdTick();

      expect(driver.calls, hasLength(1));
      expect(driver.calls.single.duration, 18);
      expect(driver.calls.single.amplitude, 170);
    });
  });
}
