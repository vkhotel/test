import '../entities/discovered_host.dart';
import '../repositories/connection_repository.dart';

/// Broadcasts a LAN discovery request and streams hosts as they answer.
class DiscoverHosts {
  const DiscoverHosts(this._repository);

  final ConnectionRepository _repository;

  Stream<List<DiscoveredHost>> call() => _repository.discoverHosts();
}
