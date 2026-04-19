import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/focus_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/vault_provider.dart';
import '../services/haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_creation_sheet.dart';
import '../widgets/task_creation_sheet.dart';
import 'focus_time_screen.dart';
import 'health_screen.dart';
import 'lecture_mode_screen.dart';
import 'note_editor_screen.dart';
import 'scratchpad_screen.dart';
import 'secure_vault_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Tasks',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    _NavItem(
      label: 'Time',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
    ),
    _NavItem(
      label: 'Scratchpad',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
    ),
    _NavItem(
      label: 'Health',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _NavItem(
      label: 'Vault',
      icon: Icons.lock_outline_rounded,
      selectedIcon: Icons.lock_rounded,
    ),
  ];

  static const List<Widget> _screens = [
    TasksScreen(),
    FocusTimeScreen(),
    ScratchpadScreen(),
    HealthScreen(),
    SecureVaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final focus = context.watch<FocusProvider>();
    final currentIndex = navigation.currentIndex;
    final isDeepWork = focus.isInDeepWork;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: AppTheme.accentBlue,
        end: isDeepWork ? AppTheme.deepWorkOrange : AppTheme.accentBlue,
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, accent, _) {
        final accentColor = accent ?? AppTheme.accentBlue;

        return Scaffold(
          body:
              IndexedStack(index: currentIndex, children: _screens),
          floatingActionButton:
              _buildFab(context, currentIndex, accentColor),
          bottomNavigationBar: SafeArea(
            top: false,
            child: _StitchBottomNav(
              selectedIndex: currentIndex,
              items: _navItems,
              accentColor: accentColor,
              onTap: (index) {
                context.read<HapticsService>().lightTick();
                // Auto-lock vault when navigating away.
                if (currentIndex == 4 && index != 4) {
                  context.read<VaultProvider>().lock();
                }
                navigation.setIndex(index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget? _buildFab(
      BuildContext context, int index, Color accentColor) {
    final IconData icon;
    final VoidCallback onPressed;

    switch (index) {
      case 0:
        icon = Icons.add_rounded;
        onPressed = () {
          context.read<HapticsService>().subtleClick();
          TaskCreationSheet.show(context);
        };
      case 1: // Focus Time Tab
        if (context.watch<FocusProvider>().selectedSegment == 0) {
          icon = Icons.add_rounded;
          onPressed = () {
            context.read<HapticsService>().subtleClick();
            AlarmCreationSheet.show(context);
          };
        } else {
          return null;
        }
      case 2:
        icon = Icons.edit_rounded;
        onPressed = () {
          context.read<HapticsService>().subtleClick();
          _showScratchpadMenu(context);
        };
      default:
        return null;
    }

    return FloatingActionButton(
      key: ValueKey<String>('fab-tab-$index'),
      onPressed: onPressed,
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const CircleBorder(),
      child: Icon(icon),
    )
        .animate()
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }

  void _showScratchpadMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.islandSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.note_add_rounded,
                    color: AppTheme.accentBlue),
                title: const Text('New Note',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Rich text editor',
                    style:
                        TextStyle(color: AppTheme.subtleGrey, fontSize: 12)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NoteEditorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.record_voice_over_rounded,
                    color: Color(0xFFBF5AF2)),
                title: const Text('Lecture Mode',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Record, transcribe & extract tasks',
                    style:
                        TextStyle(color: AppTheme.subtleGrey, fontSize: 12)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LectureModeScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Stitch Bottom Navigation – floating island with dynamic accent dot
// ═══════════════════════════════════════════════════════════════════════

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _StitchBottomNav extends StatelessWidget {
  const _StitchBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.accentColor,
    required this.onTap,
  });

  final int selectedIndex;
  final List<_NavItem> items;
  final Color accentColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.islandSurface,
          borderRadius: BorderRadius.circular(AppTheme.islandRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // ── Animated Selection Pill ────────────────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  left: selectedIndex * itemWidth + (itemWidth / 2) - 10,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(100),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),
                // ── Tab Items ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final selected = i == selectedIndex;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: SizedBox(
                        width: itemWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.selectedIcon : item.icon,
                              color: selected ? accentColor : AppTheme.subtleGrey,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? accentColor : AppTheme.subtleGrey,
                              ),
                            ).animate(target: selected ? 1 : 0).scaleXY(begin: 0.9, end: 1.0, duration: 200.ms),
                            const SizedBox(height: 2), // small buffer to avoid hitting the pill
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
