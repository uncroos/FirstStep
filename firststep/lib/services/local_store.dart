import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class LocalStore {
  static const _kTasks = 'tasks';
  static const _kRecentGuides = 'recentGuides';
  static const _kBookmarks = 'bookmarks';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------- Tasks ----------
  Future<List<TaskItem>?> loadTasks() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kTasks);
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await _prefs;
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_kTasks, raw);
  }

  // ---------- Recent Guides ----------
  Future<List<String>?> loadRecentGuides() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_kRecentGuides);
    return list; // null 가능
  }

  Future<void> saveRecentGuides(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kRecentGuides, ids);
  }

  // ---------- Bookmarks ----------
  Future<List<String>?> loadBookmarks() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_kBookmarks);
    return list;
  }

  Future<void> saveBookmarks(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kBookmarks, ids);
  }
}