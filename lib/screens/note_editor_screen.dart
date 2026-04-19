import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../providers/task_provider.dart';
import '../services/nlp_parser.dart';
import '../theme/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.onSaveVaultNote,
    this.onDeleteVaultNote,
  });

  final Note? existingNote;
  final ValueChanged<Note>? onSaveVaultNote;
  final VoidCallback? onDeleteVaultNote;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late QuillController _quillController;
  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;
  NlpTaskExtraction? _pendingExtraction;
  bool _sttAvailable = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );

    if (widget.existingNote != null &&
        widget.existingNote!.document.isNotEmpty) {
      try {
        final delta =
            Document.fromJson(jsonDecode(widget.existingNote!.document) as List);
        _quillController = QuillController(
          document: delta,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }

    _quillController.document.changes.listen((_) => _onContentChanged());
    _initStt();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize();
  }

  @override
  void dispose() {
    _save();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            hintText: 'Untitled Note',
            hintStyle: TextStyle(color: AppTheme.subtleGrey),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (widget.existingNote != null)
            IconButton(
              icon: Icon(
                widget.existingNote!.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: widget.existingNote!.isPinned
                    ? AppTheme.accentBlue
                    : AppTheme.subtleGrey,
              ),
              onPressed: () {
                context
                    .read<NoteProvider>()
                    .togglePin(widget.existingNote!.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Header Styling ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.islandSurface,
              border: Border(
                bottom: BorderSide(color: AppTheme.islandBorder, width: 0.5),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                color: AppTheme.islandSurface,
                multiRowsDisplay: false,
                showAlignmentButtons: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showFontFamily: false,
                showFontSize: false,
                showIndent: false,
                showLink: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                buttonOptions: const QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: QuillIconTheme(
                      iconButtonSelectedData: IconButtonData(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(AppTheme.accentBlue),
                        ),
                      ),
                      iconButtonUnselectedData: IconButtonData(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(AppTheme.islandSurface),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── NLP Extraction Banner ─────────────────────────────────
          if (_pendingExtraction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.accentBlue.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Task detected: "${_pendingExtraction!.taskTitle}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _extractToTasks,
                    child: const Text('Add to Tasks',
                        style: TextStyle(color: AppTheme.accentBlue)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppTheme.subtleGrey),
                    onPressed: () =>
                        setState(() => _pendingExtraction = null),
                  ),
                ],
              ),
            ),

          // ── Quill Editor ──────────────────────────────────────────
          Expanded(
            child: QuillEditor.basic(
              controller: _quillController,
              config: const QuillEditorConfig(
                placeholder: 'Start typing or tap the mic to dictate…',
                padding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),

      // ── Mic FAB ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor:
            _isListening ? AppTheme.destructiveRed : AppTheme.accentBlue,
        child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white),
      ),
      bottomNavigationBar: widget.onDeleteVaultNote != null &&
              widget.existingNote != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.destructiveRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.onDeleteVaultNote!();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Delete Secure Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ── Speech ──────────────────────────────────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize();
      if (!_sttAvailable) return;
    }

    setState(() => _isListening = true);
    await _stt.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!result.finalResult) return;
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    final index = _quillController.selection.extentOffset;
    _quillController.document.insert(index, '$text ');
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + text.length + 1),
      ChangeSource.local,
    );

    setState(() => _isListening = false);

    // ── NLP check ─────────────────────────────────────────────
    final extraction = NlpParser.tryExtract(text);
    if (extraction != null) {
      setState(() => _pendingExtraction = extraction);
    }
  }

  // ── NLP → Task ─────────────────────────────────────────────────
  void _onContentChanged() {
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isEmpty) return;

    // Check the last line for task-like patterns.
    final lines = plainText.split('\n');
    final lastLine = lines.last.trim();
    if (lastLine.length < 5) return;

    final extraction = NlpParser.tryExtract(lastLine);
    if (extraction != null && _pendingExtraction == null) {
      setState(() => _pendingExtraction = extraction);
    }
  }

  void _extractToTasks() {
    final ext = _pendingExtraction;
    if (ext == null) return;

    context.read<TaskProvider>().addTask(
      title: ext.taskTitle,
      alarmDateTime: ext.suggestedDate,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task added: "${ext.taskTitle}"'),
        backgroundColor: AppTheme.islandSurface,
      ),
    );
    setState(() => _pendingExtraction = null);
  }

  // ── Save ────────────────────────────────────────────────────────
  void _save() {
    final title = _titleController.text.trim();
    final deltaJson =
        jsonEncode(_quillController.document.toDelta().toJson());

    if (title.isEmpty && deltaJson == '[{"insert":"\\n"}]') return;

    final now = DateTime.now();
    final note = Note(
      id: widget.existingNote?.id ??
          now.millisecondsSinceEpoch.toString(),
      title: title.isNotEmpty ? title : 'Untitled',
      document: deltaJson,
      isPinned: widget.existingNote?.isPinned ?? false,
      createdAt: widget.existingNote?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.onSaveVaultNote != null) {
      widget.onSaveVaultNote!(note);
    } else {
      context.read<NoteProvider>().saveNote(note);
    }
  }
}
