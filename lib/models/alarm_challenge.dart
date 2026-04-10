import 'dart:math';

import 'alarm_trigger_payload.dart';

enum AlarmChallengeType {
  math,
  textMatch,
}

class AlarmChallenge {
  const AlarmChallenge({
    required this.type,
    required this.prompt,
    required this.expectedAnswer,
    this.displayValue = '',
  });

  final AlarmChallengeType type;
  final String prompt;
  final String expectedAnswer;
  final String displayValue;

  bool isValidAnswer(String input) {
    switch (type) {
      case AlarmChallengeType.math:
        return input.trim() == expectedAnswer;
      case AlarmChallengeType.textMatch:
        return input == expectedAnswer;
    }
  }
}

class AlarmChallengeSession {
  const AlarmChallengeSession({
    required this.payload,
    required this.challenge,
  });

  final AlarmTriggerPayload payload;
  final AlarmChallenge challenge;
}

class AlarmChallengeFactory {
  AlarmChallengeFactory({
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;

  AlarmChallenge createRandomChallenge() {
    if (_random.nextBool()) {
      return createMathChallenge();
    }
    return createTextMatchChallenge();
  }

  AlarmChallenge createMathChallenge() {
    final left = _random.nextInt(40) + 10;
    final right = _random.nextInt(9) + 2;
    final useAddition = _random.nextBool();
    final symbol = useAddition ? '+' : '-';
    final answer = useAddition ? left + right : left - right;

    return AlarmChallenge(
      type: AlarmChallengeType.math,
      prompt: 'Solve $left $symbol $right to silence the alarm.',
      expectedAnswer: '$answer',
      displayValue: '$left $symbol $right',
    );
  }

  AlarmChallenge createTextMatchChallenge() {
    const tokens = [
      'galaxy',
      'focus',
      'orbit',
      'pixel',
      'quiet',
      'anchor',
      'sprint',
      'bright',
    ];

    final parts = List<String>.generate(
      3,
      (_) => tokens[_random.nextInt(tokens.length)],
    );
    final display = parts.join(' ');

    return AlarmChallenge(
      type: AlarmChallengeType.textMatch,
      prompt: 'Type this exactly to dismiss the alarm.',
      expectedAnswer: display,
      displayValue: display,
    );
  }
}
