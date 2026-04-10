import 'package:flutter/material.dart';

import '../models/feature_panel.dart';
import 'feature_panel_card.dart';

class OneUiScreen extends StatelessWidget {
  const OneUiScreen({
    super.key,
    required this.title,
    required this.description,
    required this.panels,
  });

  final String title;
  final String description;
  final List<FeaturePanel> panels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyedSubtree(
      key: ValueKey<String>('screen-root-$title'),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: theme.textTheme.headlineLarge,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            sliver: SliverList.list(
              children: [
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                for (final panel in panels) ...[
                  FeaturePanelCard(panel: panel),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
