import 'package:flutter/material.dart';

import '../models/feature_panel.dart';
import '../widgets/one_ui_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OneUiScreen(
      title: 'Health',
      description:
          'This section is reserved for habits, recovery, and wellness metrics in a softer dashboard that still feels consistent with the rest of the app.',
      panels: [
        FeaturePanel(
          title: 'Habit overview',
          body:
              'A future home for hydration, sleep, movement, and routine tracking with strong visual hierarchy.',
          icon: Icons.favorite_border_rounded,
        ),
        FeaturePanel(
          title: 'Daily check-ins',
          body:
              'Mood, energy, and symptom logs can sit in spacious cards that are easy to review at a glance.',
          icon: Icons.monitor_heart_outlined,
        ),
      ],
    );
  }
}
