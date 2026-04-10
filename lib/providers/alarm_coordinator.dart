import 'package:flutter/foundation.dart';

import '../models/alarm_challenge.dart';
import '../models/alarm_trigger_payload.dart';

class AlarmCoordinator extends ChangeNotifier {
  AlarmCoordinator({
    AlarmChallengeFactory? challengeFactory,
  }) : _challengeFactory = challengeFactory ?? AlarmChallengeFactory();

  final AlarmChallengeFactory _challengeFactory;
  AlarmChallengeSession? _activeSession;

  AlarmChallengeSession? get activeSession => _activeSession;

  void activate(AlarmTriggerPayload payload) {
    _activeSession = AlarmChallengeSession(
      payload: payload,
      challenge: _challengeFactory.createRandomChallenge(),
    );
    notifyListeners();
  }

  void dismiss() {
    if (_activeSession == null) {
      return;
    }

    _activeSession = null;
    notifyListeners();
  }
}
