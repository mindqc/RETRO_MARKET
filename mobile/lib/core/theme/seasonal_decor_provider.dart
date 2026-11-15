import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for persisting seasonal decor toggle in SharedPreferences
const String kSeasonalDecorPrefsKey = 'seasonal_decor_enabled';

/// StateNotifier that manages the active state of seasonal holiday decor (NFR-UX-02)
class SeasonalDecorNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  SeasonalDecorNotifier([this._prefs, bool? initialValue])
      : super(initialValue ?? _prefs?.getBool(kSeasonalDecorPrefsKey) ?? true) {
    if (_prefs == null) {
      _loadFromPrefs();
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(kSeasonalDecorPrefsKey);
      if (saved != null && mounted) {
        state = saved;
      }
    } catch (_) {
      // Fallback to default true if SharedPreferences is unavailable in mock environment
    }
  }

  /// Toggles seasonal decor state and saves to SharedPreferences
  Future<void> toggle() async {
    await setEnabled(!state);
  }

  /// Sets seasonal decor state and saves to SharedPreferences
  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(kSeasonalDecorPrefsKey, value);
    } catch (_) {
      // Ignored in test environment
    }
  }
}

/// Provider for seasonal holiday decor overlay across the application
final seasonalDecorProvider = StateNotifierProvider<SeasonalDecorNotifier, bool>((ref) {
  return SeasonalDecorNotifier();
});
