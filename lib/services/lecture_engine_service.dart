import 'package:speech_to_text/speech_to_text.dart';

import '../models/note.dart';
import 'nlp_parser.dart';

/// Result of processing a recorded lecture transcript.
class LectureResult {
  const LectureResult({
    required this.markdownSummary,
    required this.extractedTasks,
    required this.wordCount,
  });

  final String markdownSummary;
  final List<NlpTaskExtraction> extractedTasks;
  final int wordCount;

  bool get isEmpty => markdownSummary.isEmpty;

  /// Convert to a savable Note.
  Note toNote() {
    final now = DateTime.now();
    final quillDelta =
        '[{"insert":"$markdownSummary\\n"}]';
    return Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Lecture — ${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      document: quillDelta,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// On-device lecture intelligence engine.
///
/// Wraps [SpeechToText] for continuous long-form capture and provides
/// a local NLP pipeline that formats the transcript into Markdown
/// paragraphs and extracts actionable tasks via regex.
class LectureEngineService {
  final SpeechToText _stt = SpeechToText();
  final StringBuffer _fullTranscript = StringBuffer();
  String _currentPartial = '';
  bool _isListening = false;
  bool _initialized = false;

  /// Called whenever the transcript updates (partial or final).
  void Function()? onUpdate;

  /// The current display text including partial recognition.
  String get displayText => _fullTranscript.toString() + _currentPartial;

  /// Full transcript without partials.
  String get finalTranscript => _fullTranscript.toString();

  bool get isListening => _isListening;

  /// Initialize the speech engine. Returns `true` if available.
  Future<bool> initialize() async {
    _initialized = await _stt.initialize(
      onStatus: (status) {
        // Auto-restart when the system stops (after pauseFor timeout)
        // to enable continuous long-form capture.
        if (status == 'notListening' && _isListening) {
          _startSession();
        }
      },
    );
    return _initialized;
  }

  /// Begin recording a lecture.
  Future<void> startListening() async {
    _fullTranscript.clear();
    _currentPartial = '';
    _isListening = true;
    await _startSession();
  }

  Future<void> _startSession() async {
    if (!_isListening || !_initialized) return;
    try {
      await _stt.listen(
        onResult: (result) {
          _currentPartial = result.recognizedWords;
          if (result.finalResult) {
            _fullTranscript.write(_currentPartial);
            _fullTranscript.write('. ');
            _currentPartial = '';
          }
          onUpdate?.call();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    } catch (_) {
      // Silently handle double-listen errors on rapid restart.
    }
  }

  /// Stop recording and flush any partial text.
  void stopListening() {
    _stt.stop();
    if (_currentPartial.isNotEmpty) {
      _fullTranscript.write(_currentPartial);
      _fullTranscript.write('. ');
      _currentPartial = '';
    }
    _isListening = false;
    onUpdate?.call();
  }

  /// Process the raw transcript into a structured [LectureResult].
  LectureResult processTranscript() {
    final raw = _fullTranscript.toString().trim();
    if (raw.isEmpty) {
      return const LectureResult(
        markdownSummary: '',
        extractedTasks: [],
        wordCount: 0,
      );
    }

    // ── Split into sentences ────────────────────────────────────
    final sentences = raw
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // ── Format into Markdown paragraphs (every 3 sentences) ──────
    final paragraphs = <String>[];
    for (var i = 0; i < sentences.length; i += 3) {
      final end = (i + 3).clamp(0, sentences.length);
      final chunk = sentences.sublist(i, end).join('. ').trim();
      if (chunk.isNotEmpty) {
        paragraphs.add(chunk.endsWith('.') ? chunk : '$chunk.');
      }
    }

    // ── Build markdown ───────────────────────────────────────────
    final buf = StringBuffer();
    buf.writeln('## Lecture Notes\n');
    for (final p in paragraphs) {
      buf.writeln(p);
      buf.writeln();
    }

    // ── Extract action items ─────────────────────────────────────
    final actions = <NlpTaskExtraction>[];
    for (final sentence in sentences) {
      final extraction = NlpParser.tryExtract(sentence);
      if (extraction != null) {
        actions.add(extraction);
      }
    }

    if (actions.isNotEmpty) {
      buf.writeln('---\n');
      buf.writeln('### Extracted Action Items\n');
      for (final a in actions) {
        buf.writeln('- [ ] ${a.taskTitle}');
      }
    }

    final wordCount = raw.split(RegExp(r'\s+')).length;

    return LectureResult(
      markdownSummary: buf.toString().trim(),
      extractedTasks: actions,
      wordCount: wordCount,
    );
  }

  void dispose() {
    _stt.stop();
    _isListening = false;
  }
}
