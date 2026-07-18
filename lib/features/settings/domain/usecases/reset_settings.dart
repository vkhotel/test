import '../../../../core/utils/result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class ResetSettings {
  const ResetSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<AppSettings>> call() => _repository.resetToDefaults();
}
