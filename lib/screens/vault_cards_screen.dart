import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/vault_provider.dart';
import 'vault_card_scanner_screen.dart';

class VaultCardsScreen extends StatefulWidget {
  const VaultCardsScreen({super.key});

  @override
  State<VaultCardsScreen> createState() => _VaultCardsScreenState();
}

class _VaultCardsScreenState extends State<VaultCardsScreen> {
  late Box _box;
  bool _isInit = false;
  List<_CardEntry> _cards = [];

  @override
  void initState() {
    super.initState();
    final vault = context.read<VaultProvider>();
    _initHive(vault);
  }

  Future<void> _initHive(VaultProvider vault) async {
    _box = await vault.openEncryptedBox('vault_cards');
    if (!mounted) return;
    _loadEntries();
  }

  void _loadEntries() {
    final list = _box.values.toList();
    if (list.isEmpty) {
      _cards = List.from(_defaultCards);
    } else {
      final keys = _box.keys.toList();
      final validEntries = <_CardEntry>[];
      for (var i = 0; i < list.length; i++) {
        final e = list[i];
        final k = keys[i];
        if (e is Map) {
          validEntries.add(_CardEntry(
            key: k,
            bank: e['bank']?.toString() ?? 'Bank',
            last4: e['last4']?.toString() ?? '0000',
            holder: e['holder']?.toString() ?? '',
            color: AppTheme.accentBlue,
          ));
        }
      }
      _cards = validEntries;
    }
    setState(() => _isInit = true);
  }

  Future<void> _showScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VaultCardScannerScreen()),
    );
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(title: const Text('Payment Cards')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScanner,
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: !_isInit ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        itemCount: _cards.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final card = _cards[i];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(AppTheme.islandRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: card.color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(Icons.credit_card_rounded, color: card.color, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.bank,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('**** **** **** ${card.last4}',
                          style: const TextStyle(
                              color: AppTheme.subtleGrey, 
                              fontSize: 14,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (card.key != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.subtleGrey, size: 20),
                    onPressed: () async {
                      await _box.delete(card.key);
                      _loadEntries();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const List<_CardEntry> _defaultCards = [
    _CardEntry(
      bank: 'Chase Sapphire',
      last4: '4192',
      holder: 'John Doe',
      color: Color(0xFF005F9E),
    ),
    _CardEntry(
      bank: 'Amex Platinum',
      last4: '1005',
      holder: 'John Doe',
      color: Color(0xFFC0C0C0),
    ),
  ];
}

class _CardEntry {
  const _CardEntry({
    this.key,
    required this.bank,
    required this.last4,
    required this.holder,
    required this.color,
  });

  final dynamic key;
  final String bank;
  final String last4;
  final String holder;
  final Color color;
}
