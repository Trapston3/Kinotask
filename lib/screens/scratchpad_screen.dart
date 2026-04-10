import 'package:flutter/material.dart';

import '../models/feature_panel.dart';
import '../widgets/one_ui_screen.dart';

class ScratchpadScreen extends StatelessWidget {
  const ScratchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OneUiScreen(
      title: 'Scratchpad',
      description:
          'A fast capture surface for loose notes, fragments, and quick ideas before they are sorted into more structured workflows.',
      panels: [
        FeaturePanel(
          title: 'Quick capture',
          body:
              'Designed for zero-friction jotting so ideas can land instantly without fighting form fields or navigation.',
          icon: Icons.edit_note_rounded,
        ),
        FeaturePanel(
          title: 'Conversion zone',
          body:
              'Later, these notes can become tasks, vault entries, or health logs from the same bottom-heavy shell.',
          icon: Icons.sync_alt_rounded,
        ),
      ],
    );
  }
}
