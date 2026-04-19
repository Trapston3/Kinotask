import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kinotask_header.dart';
import 'note_editor_screen.dart';

class ScratchpadScreen extends StatelessWidget {
  const ScratchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final pinned = provider.pinnedNotes;
    final unpinned = provider.unpinnedNotes;
    final allNotes = [...pinned, ...unpinned];

    // Split into two columns for masonry layout.
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < allNotes.length; i++) {
      final card = _NoteCard(
        note: allNotes[i],
        onTap: () => _openEditor(context, allNotes[i]),
        onDelete: () => provider.deleteNote(allNotes[i].id),
      )
          .animate(delay: Duration(milliseconds: 80 * i))
          .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
          .slideY(
              begin: 0.08,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutBack);
      (i.isEven ? left : right)
        ..add(card)
        ..add(const SizedBox(height: 12));
    }

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: const KinotaskHeader('Scratchpad'),
            ),
          ),
          if (allNotes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.islandSurface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.islandRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 64,
                          color:
                              AppTheme.accentBlue.withValues(alpha: 0.6)),
                      const SizedBox(height: 20),
                      const Text(
                        'No Notes Yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the pencil to create your first note.',
                        style: TextStyle(
                          color: AppTheme.subtleGrey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: left)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(children: right)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, [Note? note]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(existingNote: note),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Note Card
// ═══════════════════════════════════════════════════════════════════════

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.islandSurface,
          borderRadius: BorderRadius.circular(AppTheme.islandRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (note.isPinned)
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppTheme.accentBlue,
                  ),
              ],
            ),
            if (note.preview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                note.preview,
                style: const TextStyle(
                  color: AppTheme.subtleGrey,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              note.timestampLabel,
              style: TextStyle(
                color: AppTheme.subtleGrey.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.islandSurface,
        title: const Text('Delete Note?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppTheme.subtleGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.destructiveRed)),
          ),
        ],
      ),
    );
  }
}
