import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/vault_provider.dart';

class VaultPasswordsScreen extends StatefulWidget {
  const VaultPasswordsScreen({super.key});

  @override
  State<VaultPasswordsScreen> createState() =>
      _VaultPasswordsScreenState();
}

class _VaultPasswordsScreenState extends State<VaultPasswordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late Box _box;
  bool _isInit = false;

  List<_PasswordEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    final vault = context.read<VaultProvider>();
    _initHive(vault);
  }

  Future<void> _initHive(VaultProvider vault) async {
    _box = await vault.openEncryptedBox('vault_passwords');
    if (!mounted) return;
    _loadEntries();
  }

  void _loadEntries() {
    final list = _box.values.toList();
    if (list.isEmpty) {
      _entries = List.from(_defaultEntries);
    } else {
      final validEntries = <_PasswordEntry>[];
      final keys = _box.keys.toList();
      for (var i = 0; i < list.length; i++) {
        final e = list[i];
        final k = keys[i];
        try {
          if (e is Map) {
            validEntries.add(_PasswordEntry(
              key: k,
              name: e['name']?.toString() ?? 'Unknown',
              username: e['username']?.toString() ?? '',
              password: e['password']?.toString() ?? '',
              icon: Icons.vpn_key_rounded,
              color: AppTheme.accentBlue,
            ));
          }
        } catch (_) {}
      }
      _entries = validEntries;
    }
    setState(() => _isInit = true);
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final csvString = await file.readAsString();
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) return;
    
    // Attempt basic mapping (assumes url/name, username, password columns exist)
    int nameIdx = 0, userIdx = 1; // naive defaults

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;
      final name = row[nameIdx].toString();
      final user = row[userIdx].toString();
      final pass = row.length > 2 ? row[2].toString() : '';
      if (name.isNotEmpty) {
        _box.add({
          'name': name,
          'username': user,
          'password': pass,
        });
      }
    }
    _loadEntries();
  }

  void _manualAdd() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'App/Website', hintStyle: const TextStyle(color: AppTheme.subtleGrey), filled: true, fillColor: AppTheme.islandSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Username / Email', hintStyle: const TextStyle(color: AppTheme.subtleGrey), filled: true, fillColor: AppTheme.islandSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Password', hintStyle: const TextStyle(color: AppTheme.subtleGrey), filled: true, fillColor: AppTheme.islandSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty) {
                      await _box.add({
                        'name': nameCtrl.text,
                        'username': userCtrl.text,
                        'password': passCtrl.text,
                      });
                      _loadEntries();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static const List<_PasswordEntry> _defaultEntries = [
    _PasswordEntry(
        name: 'Google',
        username: 'user@gmail.com',
        password: 'password123',
        icon: Icons.mail_rounded,
        color: Color(0xFFEA4335)),
    _PasswordEntry(
        name: 'Netflix',
        username: 'user@email.com',
        password: 'password123',
        icon: Icons.movie_rounded,
        color: Color(0xFFE50914)),
    _PasswordEntry(
        name: 'Spotify',
        username: 'musiclover',
        password: 'password123',
        icon: Icons.music_note_rounded,
        color: Color(0xFF1DB954)),
    _PasswordEntry(
        name: 'GitHub',
        username: 'dev_user',
        password: 'password123',
        icon: Icons.code_rounded,
        color: Color(0xFF6E5494)),
    _PasswordEntry(
        name: 'Twitter / X',
        username: '@handle',
        password: 'password123',
        icon: Icons.alternate_email_rounded,
        color: Color(0xFF1DA1F2)),
    _PasswordEntry(
        name: 'Amazon',
        username: 'buyer@email.com',
        password: 'password123',
        icon: Icons.shopping_bag_rounded,
        color: Color(0xFFFF9900)),
    _PasswordEntry(
        name: 'Discord',
        username: 'gamer#1234',
        password: 'password123',
        icon: Icons.headset_mic_rounded,
        color: Color(0xFF5865F2)),
    _PasswordEntry(
        name: 'LinkedIn',
        username: 'professional',
        password: 'password123',
        icon: Icons.work_rounded,
        color: Color(0xFF0A66C2)),
    _PasswordEntry(
        name: 'Steam',
        username: 'steamuser',
        password: 'password123',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF1B2838)),
    _PasswordEntry(
        name: 'Apple ID',
        username: 'user@icloud.com',
        password: 'password123',
        icon: Icons.phone_iphone_rounded,
        color: Color(0xFF555555)),
    _PasswordEntry(
        name: 'Bank App',
        username: '****4832',
        password: 'password123',
        icon: Icons.account_balance_rounded,
        color: Color(0xFF00695C)),
    _PasswordEntry(
        name: 'Instagram',
        username: '@instauser',
        password: 'password123',
        icon: Icons.camera_alt_rounded,
        color: Color(0xFFE1306C)),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _entries
        : _entries
            .where((e) =>
                e.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: const Text('Passwords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.accentBlue),
            onPressed: _importCsv,
            tooltip: 'Import CSV',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _manualAdd,
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: !_isInit ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search passwords…',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.subtleGrey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.subtleGrey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = filtered[i];
                return GestureDetector(
                  onTap: () => _showPreviewSheet(e),
                  child: _PasswordCard(entry: e),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _showPreviewSheet(_PasswordEntry entry) {
    bool isVisible = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.islandSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: entry.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(entry.icon, color: entry.color, size: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Account', style: TextStyle(color: AppTheme.subtleGrey)),
                  const SizedBox(height: 4),
                  Text(entry.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Username', style: TextStyle(color: AppTheme.subtleGrey)),
                  const SizedBox(height: 4),
                  Text(entry.username, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password', style: TextStyle(color: AppTheme.subtleGrey)),
                          const SizedBox(height: 4),
                          Text(
                            isVisible ? entry.password : '••••••••••••',
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: isVisible ? 18 : 16,
                              letterSpacing: isVisible ? 0.5 : 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.subtleGrey),
                        onPressed: () => setSheetState(() => isVisible = !isVisible),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.destructiveRed,
                        side: const BorderSide(color: AppTheme.destructiveRed, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Credential'),
                      onPressed: () async {
                        if (entry.key != null) {
                          await _box.delete(entry.key);
                          _loadEntries();
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

class _PasswordEntry {
  const _PasswordEntry({
    this.key,
    required this.name,
    required this.username,
    required this.password,
    required this.icon,
    required this.color,
  });

  final dynamic key;
  final String name;
  final String username;
  final String password;
  final IconData icon;
  final Color color;
}

class _PasswordCard extends StatefulWidget {
  const _PasswordCard({required this.entry});

  final _PasswordEntry entry;

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.islandSurface,
        borderRadius: BorderRadius.circular(AppTheme.islandRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.entry.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(widget.entry.icon, color: widget.entry.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.entry.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(widget.entry.username,
                    style: const TextStyle(
                        color: AppTheme.subtleGrey, fontSize: 13)),
                if (_showPassword) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.password,
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppTheme.subtleGrey,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _showPassword = !_showPassword),
          ),
        ],
      ),
    );
  }
}
