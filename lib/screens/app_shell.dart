import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_destination.dart';
import '../providers/navigation_provider.dart';
import '../widgets/task_creation_sheet.dart';
import 'health_screen.dart';
import 'scratchpad_screen.dart';
import 'secure_vault_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<AppDestination> _destinations = [
    AppDestination(
      label: 'Tasks',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist_rounded,
      screen: TasksScreen(),
    ),
    AppDestination(
      label: 'Scratchpad',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note_rounded,
      screen: ScratchpadScreen(),
    ),
    AppDestination(
      label: 'Health',
      icon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      screen: HealthScreen(),
    ),
    AppDestination(
      label: 'Secure Vault',
      icon: Icons.lock_outline_rounded,
      selectedIcon: Icons.lock_rounded,
      screen: SecureVaultScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: _destinations[navigation.currentIndex].screen,
      floatingActionButton: navigation.currentIndex == 0
          ? FloatingActionButton.large(
              key: const ValueKey<String>('tasks-add-fab'),
              onPressed: () => TaskCreationSheet.show(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: NavigationBar(
                selectedIndex: navigation.currentIndex,
                onDestinationSelected: navigation.setIndex,
                destinations: [
                  for (final destination in _destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
