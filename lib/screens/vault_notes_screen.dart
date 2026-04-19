import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/note.dart';
import '../providers/vault_provider.dart';
import 'note_editor_screen.dart';

class VaultNotesScreen extends StatefulWidget {
  const VaultNotesScreen({super.key});

  @override
  State<VaultNotesScreen> createState() => _VaultNotesScreenState();
}

class _VaultNotesScreenState extends State<VaultNotesScreen> {
  late Box _box;
  bool _isInit = false;
  List<_SecureNote> _notes = [];

  @override
  void initState() {
    super.initState();
    final vault = context.read<VaultProvider>();
    _initHive(vault);
  }

  Future<void> _initHive(VaultProvider vault) async {
    _box = await vault.openEncryptedBox('vault_notes');
    if (!mounted) return;
    _loadNotes();
  }

  void _loadNotes() {
    final validNotes = <_SecureNote>[];
    for (final e in _box.values) {
      try {
        if (e is Map) {
          validNotes.add(_SecureNote(
            id: e['id']?.toString() ?? '',
            title: e['title']?.toString() ?? 'Untitled',
            content: e['content']?.toString() ?? '',
            date: e['date']?.toString() ?? '',
          ));
        }
      } catch (_) {}
    }
    _notes = validNotes;
    setState(() => _isInit = true);
  }

  void _addOrEditNote([_SecureNote? note]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: note != null
              ? Note(
                  id: note.id,
                  title: note.title,
                  document: note.content.isEmpty ? '[{"insert":"\\n"}]' : note.content,
                  isPinned: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                )
              : null,
          onSaveVaultNote: (Note savedNote) async {
            final id = savedNote.id;
            await _box.put(id, {
              'id': id,
              'title': savedNote.title,
              'content': savedNote.document,
              'date': '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
            });
            _loadNotes();
          },
          onDeleteVaultNote: note == null
              ? null
              : () async {
                  await _box.delete(note.id);
                  _loadNotes();
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: const Text('Secure Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: !_isInit
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('No secure notes', style: TextStyle(color: AppTheme.subtleGrey)))
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  itemCount: _notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final note = _notes[i];
                    return GestureDetector(
                      onTap: () => _addOrEditNote(note),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.islandSurface,
                          borderRadius: BorderRadius.circular(AppTheme.islandRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.subtleGrey),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, duration: 400.ms),
                    );
                  },
                ),
    );
  }
}

class _SecureNote {
  const _SecureNote({required this.id, required this.title, required this.content, required this.date});
  final String id;
  final String title;
  final String content;
  final String date;
}
