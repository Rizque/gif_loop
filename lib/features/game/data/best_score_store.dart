import 'package:shared_preferences/shared_preferences.dart';

class BestScoreStore {
  const new(this._preferences);

  static const String _key = 'game_best_score';

  final SharedPreferences _preferences;

  int get bestScore => _preferences.getInt(_key) ?? 0;

  Future<void> save(int score) => _preferences.setInt(_key, score);
}
