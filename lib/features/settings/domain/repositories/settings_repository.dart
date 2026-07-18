import '../../../../core/utils/result.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  /// Synchronous by design: [SharedPreferences] is already fully loaded into
  /// memory by the time this is called (after `await SharedPreferences
  /// .getInstance()` in `main()`), so there's no need to force every read
  /// through the UI as a loading state.
  Result<AppSettings> loadSettings();

  Future<Result<void>> saveSettings(AppSettings settings);

  Future<Result<AppSettings>> resetToDefaults();
}
