import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesRepository {
  new(this._preferences);

  static const int maxEntries = 10;
  static const String _key = 'recent_searches';

  final SharedPreferencesAsync _preferences;

  Future<List<String>> load() async =>
      await _preferences.getStringList(_key) ?? const [];

  Future<List<String>> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return await load();
    final normalized = trimmed.toLowerCase();
    final current = await load();
    return await _save(
      [
        trimmed,
        ...current.where((entry) => entry.toLowerCase() != normalized),
      ].take(maxEntries).toList(),
    );
  }

  Future<List<String>> remove(String query) async {
    final current = await load();
    return await _save(current.where((entry) => entry != query).toList());
  }

  Future<List<String>> clear() async {
    await _preferences.remove(_key);
    return const [];
  }

  Future<List<String>> _save(List<String> entries) async {
    await _preferences.setStringList(_key, entries);
    return entries;
  }
}
