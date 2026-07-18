import '../../../../core/utils/result.dart';
import '../repositories/connection_repository.dart';

/// Sends a single already-serialized command payload to the desktop.
class SendCommand {
  const SendCommand(this._repository);

  final ConnectionRepository _repository;

  Future<Result<void>> call(Map<String, dynamic> payload) => _repository.sendCommand(payload);
}
