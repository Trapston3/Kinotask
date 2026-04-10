import 'package:flutter/material.dart';

import '../models/feature_panel.dart';
import '../services/vault_service.dart';
import '../widgets/one_ui_screen.dart';

class SecureVaultScreen extends StatelessWidget {
  const SecureVaultScreen({
    super.key,
    this.vaultService = const VaultService(),
  });

  final VaultService vaultService;

  @override
  Widget build(BuildContext context) {
    return OneUiScreen(
      title: 'Secure Vault',
      description:
          'Private documents, sensitive notes, and locked references will live here behind a dedicated security flow.',
      panels: [
        FeaturePanel(
          title: vaultService.statusHeadline,
          body: vaultService.statusBody,
          icon: Icons.lock_outline_rounded,
        ),
        const FeaturePanel(
          title: 'Protected records',
          body:
              'The shell is ready for encrypted storage, secure attachments, and biometrics without changing the app-wide navigation pattern.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}
