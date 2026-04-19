import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kinotask_header.dart';
import 'vault_passwords_screen.dart';
import 'vault_documents_screen.dart';
import 'vault_notes_screen.dart';
import 'vault_cards_screen.dart';

class SecureVaultScreen extends StatelessWidget {
  const SecureVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<VaultProvider>();

    return SafeArea(
      child: vault.isUnlocked
          ? _UnlockedVault()
          : _LockedVault(isAuthenticating: vault.isAuthenticating),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Locked state — fingerprint island
// ═══════════════════════════════════════════════════════════════════════

class _LockedVault extends StatelessWidget {
  const _LockedVault({required this.isAuthenticating});

  final bool isAuthenticating;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: AppTheme.accentBlue, size: 28),
                const SizedBox(width: 12),
                const KinotaskHeader('Vault'),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Your protected space',
                style:
                    TextStyle(color: AppTheme.subtleGrey, fontSize: 15)),
            const SizedBox(height: 48),

            // ── Biometric island ──────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.islandSurface,
                borderRadius:
                    BorderRadius.circular(AppTheme.islandRadius),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          AppTheme.accentBlue.withValues(alpha: 0.1),
                    ),
                    child: isAuthenticating
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                strokeWidth: 3),
                          )
                        : const Icon(Icons.fingerprint_rounded,
                            size: 48, color: AppTheme.accentBlue),
                  ),
                  const SizedBox(height: 20),
                  const Text('Authenticate to Access',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Use biometrics or your device PIN to\nunlock sensitive data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.subtleGrey, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isAuthenticating
                          ? null
                          : () =>
                              context.read<VaultProvider>().tryUnlock(),
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock Vault'),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 700.ms, curve: Curves.easeOutExpo)
                .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Unlocked state — category grid
// ═══════════════════════════════════════════════════════════════════════

class _UnlockedVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open_rounded,
                    color: AppTheme.accentBlue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: KinotaskHeader('Vault'),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_rounded,
                      color: AppTheme.subtleGrey),
                  onPressed: () =>
                      context.read<VaultProvider>().lock(),
                  tooltip: 'Lock',
                ),
              ],
            ),
            const SizedBox(height: 32),

            _VaultCategory(
              title: 'Passwords',
              subtitle: '12 entries',
              icon: Icons.key_rounded,
              color: const Color(0xFFFF9F0A),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const VaultPasswordsScreen()),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            _VaultCategory(
              title: 'Documents',
              subtitle: '5 files',
              icon: Icons.description_rounded,
              color: const Color(0xFF34C759),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const VaultDocumentsScreen()),
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            _VaultCategory(
              title: 'Secure Notes',
              subtitle: 'Encrypted thought pieces',
              icon: Icons.notes_rounded,
              color: const Color(0xFF5E5CE6),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const VaultNotesScreen()),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            _VaultCategory(
              title: 'Payment Cards',
              subtitle: 'Scan & store',
              icon: Icons.credit_card_rounded,
              color: const Color(0xFFBF5AF2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const VaultCardsScreen()),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}

class _VaultCategory extends StatelessWidget {
  const _VaultCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.islandSurface,
          borderRadius: BorderRadius.circular(AppTheme.islandRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.subtleGrey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.subtleGrey, size: 24),
          ],
        ),
      ),
    );
  }
}
