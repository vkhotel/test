import '../repositories/connection_repository.dart';

/// Tears down the active connection and disables auto-reconnect for it.
class DisconnectFromHost {
  const DisconnectFromHost(this._repository);

  final ConnectionRepository _repository;

  Future<void> call() => _repository.disconnect();
}
