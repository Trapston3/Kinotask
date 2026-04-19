import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';

class NoteStorageService {
  static const String _boxName = 'notes';

  Future<List<Note>> loadNotes() async {
    final box = await Hive.openBox<String>(_boxName);
    final validNotes = <Note>[];

    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          validNotes.add(Note.fromJson(decoded));
        } else if (decoded is Map) {
          validNotes.add(Note.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (e) {
        debugPrint('Failed to parse a Note: $e');
      }
    }

    validNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return validNotes;
  }

  Future<void> saveNote(Note note) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> deleteNote(String id) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.delete(id);
  }
}
