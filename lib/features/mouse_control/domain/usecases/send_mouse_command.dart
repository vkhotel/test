import '../../../../core/utils/result.dart';
import '../../../connection/domain/repositories/connection_repository.dart';
import '../entities/mouse_command.dart';

/// The one place a [MouseCommand] gets turned into wire bytes. Mouse control
/// depends on the connection feature's domain contract (not its data layer),
/// which is the normal, allowed direction for cross-feature composition.
class SendMouseCommand {
  const SendMouseCommand(this._connectionRepository);

  final ConnectionRepository _connectionRepository;

  Future<Result<void>> call(MouseCommand command) {
    return _connectionRepository.sendCommand(command.toJson());
  }
}
