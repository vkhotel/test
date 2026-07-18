import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/app_settings_model.dart';

/// Reads/writes [AppSettingsModel] as a single JSON blob in
/// [SharedPreferences] under [AppConstants.prefsSettingsKey].
class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  AppSettingsModel load() {
    final raw = _prefs.getString(AppConstants.prefsSettingsKey);
    if (raw == null) {
      return AppSettingsModel.fromJson(const {});
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(json);
    } catch (e) {
      throw CacheException('Stored settings are corrupted: $e');
    }
  }

  Future<void> save(AppSettingsModel settings) async {
    final success = await _prefs.setString(
      AppConstants.prefsSettingsKey,
      jsonEncode(settings.toJson()),
    );
    if (!success) {
      throw const CacheException('SharedPreferences refused the write.');
    }
  }

  Future<void> clear() async {
    await _prefs.remove(AppConstants.prefsSettingsKey);
  }
}
