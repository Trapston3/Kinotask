import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/note_provider.dart';
import '../providers/task_provider.dart';
import '../services/lecture_engine_service.dart';
import '../theme/app_theme.dart';

class LectureModeScreen extends StatefulWidget {
  const LectureModeScreen({super.key});

  @override
  State<LectureModeScreen> createState() => _LectureModeScreenState();
}

class _LectureModeScreenState extends State<LectureModeScreen> {
  final LectureEngineService _engine = LectureEngineService();
  final ScrollController _scrollController = ScrollController();
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  LectureResult? _result;
  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _engine.onUpdate = () {
      if (mounted) setState(() {});
      _autoScroll();
    };
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engineReady = await _engine.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _engine.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: const Text('Lecture Mode'),
        actions: [
          if (_engine.isListening)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.destructiveRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.destructiveRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmtDuration(_elapsed),
                        style: const TextStyle(
                          color: AppTheme.destructiveRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _result != null ? _buildResult() : _buildRecorder(),
    );
  }

  // ── Recorder view ──────────────────────────────────────────────
  Widget _buildRecorder() {
    return Column(
      children: [
        // ── Live transcript ───────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.islandSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _engine.displayText.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.record_voice_over_rounded,
                              size: 48,
                              color: AppTheme.subtleGrey
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap the mic to start\nrecording your lecture',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.subtleGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        _engine.displayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Controls ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_engine.isListening) ...[
                // Stop & Process
                GestureDetector(
                  onTap: _stopAndProcess,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.destructiveRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_rounded,
                            color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Stop & Process',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                ),
              ] else ...[
                // Start recording
                GestureDetector(
                  onTap: _engineReady ? _startRecording : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _engineReady
                          ? AppTheme.accentBlue
                          : AppTheme.subtleGrey,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 36),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 500.ms),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Result view ────────────────────────────────────────────────
  Widget _buildResult() {
    final result = _result!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                    label: 'Words', value: '${result.wordCount}'),
                _StatChip(
                    label: 'Duration', value: _fmtDuration(_elapsed)),
                _StatChip(
                    label: 'Actions',
                    value: '${result.extractedTasks.length}'),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
              .slideY(
                  begin: 0.06,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutBack),
          const SizedBox(height: 16),

          // ── Markdown preview ───────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              result.markdownSummary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
              .slideY(
                  begin: 0.06,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutBack),
          const SizedBox(height: 24),

          // ── Actions ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveAsNote,
                  icon: const Icon(Icons.note_add_rounded),
                  label: const Text('Save as Note'),
                ),
              ),
              if (result.extractedTasks.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _extractAllTasks,
                    icon: const Icon(Icons.add_task_rounded),
                    label: Text(
                        'Add ${result.extractedTasks.length} Tasks'),
                  ),
                ),
              ],
            ],
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
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _startRecording() {
    _engine.startListening();
    _elapsed = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() {});
  }

  void _stopAndProcess() {
    _elapsedTimer?.cancel();
    _engine.stopListening();
    final result = _engine.processTranscript();
    setState(() => _result = result);
  }

  void _saveAsNote() {
    final note = _result!.toNote();
    context.read<NoteProvider>().saveNote(note);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lecture saved as note'),
        backgroundColor: AppTheme.islandSurface,
      ),
    );
    Navigator.of(context).pop();
  }

  void _extractAllTasks() {
    for (final ext in _result!.extractedTasks) {
      context.read<TaskProvider>().addTask(
            title: ext.taskTitle,
            alarmDateTime: ext.suggestedDate,
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${_result!.extractedTasks.length} tasks extracted'),
        backgroundColor: AppTheme.islandSurface,
      ),
    );
  }

  void _autoScroll() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: 200.ms,
        curve: Curves.easeOut,
      );
    }
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              color: AppTheme.subtleGrey,
              fontSize: 12,
            )),
      ],
    );
  }
}
