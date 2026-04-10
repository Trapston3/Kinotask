import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/models/alarm_challenge.dart';

void main() {
  group('AlarmChallengeFactory', () {
    test('builds a solvable math challenge', () {
      final factory = AlarmChallengeFactory(random: Random(1));
      final challenge = factory.createMathChallenge();

      expect(challenge.type, AlarmChallengeType.math);
      expect(challenge.prompt.trim(), isNotEmpty);
      expect(challenge.isValidAnswer(challenge.expectedAnswer), isTrue);
      expect(challenge.isValidAnswer('9999'), isFalse);
    });

    test('builds a text-match challenge that requires exact input', () {
      final factory = AlarmChallengeFactory(random: Random(2));
      final challenge = factory.createTextMatchChallenge();

      expect(challenge.type, AlarmChallengeType.textMatch);
      expect(challenge.displayValue.trim(), isNotEmpty);
      expect(challenge.isValidAnswer(challenge.expectedAnswer), isTrue);
      expect(
        challenge.isValidAnswer('${challenge.expectedAnswer} '),
        isFalse,
      );
    });
  });
}
