import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class PracticeStore {
  PracticeStore(this._prefs);

  final SharedPreferences _prefs;

  static const practicesKey = 'swimset.v2.practices';
  static const draftKey = 'swimset.v2.draft';
  static const themeKey = 'swimset.v2.theme';

  static Future<PracticeStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PracticeStore(prefs);
  }

  List<Practice> listPractices() {
    final raw = _prefs.getString(practicesKey);
    if (raw == null || raw.isEmpty) return <Practice>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Practice>[];
      final items = decoded
          .whereType<Map>()
          .map((entry) => normalizePractice(Map<String, dynamic>.from(entry)))
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (_) {
      return <Practice>[];
    }
  }

  Future<void> _writePractices(List<Practice> practices) async {
    await _prefs.setString(
      practicesKey,
      jsonEncode(practices.map((practice) => practice.toJson()).toList()),
    );
  }

  Future<void> savePractice(Practice practice) async {
    final practices = listPractices();
    final index = practices.indexWhere((item) => item.id == practice.id);
    practice.updatedAt = DateTime.now().toIso8601String();
    if (index >= 0) {
      practices[index] = practice;
    } else {
      practices.add(practice);
    }
    await _writePractices(practices);
  }

  Future<void> deletePractice(String id) async {
    final practices = listPractices()..removeWhere((practice) => practice.id == id);
    await _writePractices(practices);
  }

  Future<void> saveDraft(Practice practice) async {
    await _prefs.setString(draftKey, jsonEncode(practice.toJson()));
  }

  Practice? loadDraft() {
    final raw = _prefs.getString(draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return normalizePractice(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  ThemeMode loadTheme() {
    switch (_prefs.getString(themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveTheme(ThemeMode mode) async {
    await _prefs.setString(themeKey, mode.name);
  }

  /// Accepts a single practice, a list, or { "practices": [...] }.
  /// Returns the number of practices imported.
  Future<int> importJson(String text) async {
    final decoded = jsonDecode(text);
    final incoming = <Practice>[];
    if (decoded is List) {
      for (final entry in decoded.whereType<Map>()) {
        incoming.add(normalizePractice(Map<String, dynamic>.from(entry)));
      }
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['practices'] is List) {
        for (final entry in (map['practices'] as List).whereType<Map>()) {
          incoming.add(normalizePractice(Map<String, dynamic>.from(entry)));
        }
      } else if (map['sets'] is List) {
        incoming.add(normalizePractice(map));
      }
    }
    if (incoming.isEmpty) {
      throw const FormatException('No practices found in that file.');
    }
    final practices = listPractices();
    for (final practice in incoming) {
      final index = practices.indexWhere((item) => item.id == practice.id);
      if (index >= 0) {
        practices[index] = practice;
      } else {
        practices.add(practice);
      }
    }
    await _writePractices(practices);
    return incoming.length;
  }

  String exportAllJson() {
    final practices = listPractices();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'SwimSet',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'practices': practices.map((practice) => practice.toJson()).toList(),
    });
  }

  int storageBytes() {
    final practices = _prefs.getString(practicesKey) ?? '';
    final draft = _prefs.getString(draftKey) ?? '';
    return utf8.encode(practices).length + utf8.encode(draft).length;
  }
}
