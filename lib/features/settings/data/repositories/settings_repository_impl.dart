import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Result<AppSettings> loadSettings() {
    try {
      return Result.success(_localDataSource.load());
    } on CacheException catch (e) {
      return Result.failure(StorageFailure(e.message));
    } catch (e) {
      return Result.failure(StorageFailure('$e'));
    }
  }

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    try {
      await _localDataSource.save(AppSettingsModel.fromEntity(settings));
      return const Result.success(null);
    } on CacheException catch (e) {
      return Result.failure(StorageFailure(e.message));
    } catch (e) {
      return Result.failure(StorageFailure('$e'));
    }
  }

  @override
  Future<Result<AppSettings>> resetToDefaults() async {
    try {
      final defaults = AppSettings.defaults();
      await _localDataSource.save(AppSettingsModel.fromEntity(defaults));
      return Result.success(defaults);
    } on CacheException catch (e) {
      return Result.failure(StorageFailure(e.message));
    } catch (e) {
      return Result.failure(StorageFailure('$e'));
    }
  }
}
