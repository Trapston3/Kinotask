import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/note_storage_service.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider({NoteStorageService? storage})
      : _storage = storage ?? NoteStorageService();

  final NoteStorageService _storage;
  List<Note> _notes = [];
  bool _isReady = false;

  List<Note> get notes => List.unmodifiable(_notes);
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((n) => !n.isPinned).toList();
  bool get isReady => _isReady;

  Future<void> initialize() async {
    _notes = await _storage.loadNotes();
    _isReady = true;
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _notes[idx] = note;
    } else {
      _notes.insert(0, note);
    }
    await _storage.saveNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _storage.deleteNote(id);
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final note = _notes[idx].copyWith(isPinned: !_notes[idx].isPinned);
    _notes[idx] = note;
    await _storage.saveNote(note);
    notifyListeners();
  }
}
