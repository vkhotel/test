import '../../../../core/utils/result.dart';
import '../repositories/connection_repository.dart';

/// Connects to a chosen desktop receiver by IP + port.
class ConnectToHost {
  const ConnectToHost(this._repository);

  final ConnectionRepository _repository;

  Future<Result<void>> call(String ip, int port, {String? hostName}) =>
      _repository.connect(ip, port, hostName: hostName);
}
