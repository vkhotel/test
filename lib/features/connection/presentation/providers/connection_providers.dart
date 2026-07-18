import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/network_info_datasource.dart';
import '../../data/datasources/udp_discovery_datasource.dart';
import '../../data/datasources/websocket_datasource.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/connect_to_host.dart';
import '../../domain/usecases/disconnect_from_host.dart';
import '../../domain/usecases/discover_hosts.dart';
import '../../domain/usecases/send_command.dart';

final webSocketDataSourceProvider = Provider<WebSocketDataSource>((ref) {
  return WebSocketDataSource();
});

final udpDiscoveryDataSourceProvider = Provider<UdpDiscoveryDataSource>((ref) {
  return UdpDiscoveryDataSource();
});

final networkInfoDataSourceProvider = Provider<NetworkInfoDataSource>((ref) {
  return NetworkInfoDataSource();
});

/// The single, app-lifetime [ConnectionRepository] instance. Every provider
/// below (and every feature that needs connection state) reads through this
/// one provider, so there is exactly one WebSocket connection in the app.
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final repository = ConnectionRepositoryImpl(
    webSocketDataSource: ref.watch(webSocketDataSourceProvider),
    discoveryDataSource: ref.watch(udpDiscoveryDataSourceProvider),
    networkInfoDataSource: ref.watch(networkInfoDataSourceProvider),
    batteryService: ref.watch(batteryServiceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final connectToHostUseCaseProvider = Provider<ConnectToHost>((ref) {
  return ConnectToHost(ref.watch(connectionRepositoryProvider));
});

final disconnectFromHostUseCaseProvider = Provider<DisconnectFromHost>((ref) {
  return DisconnectFromHost(ref.watch(connectionRepositoryProvider));
});

final discoverHostsUseCaseProvider = Provider<DiscoverHosts>((ref) {
  return DiscoverHosts(ref.watch(connectionRepositoryProvider));
});

final sendCommandUseCaseProvider = Provider<SendCommand>((ref) {
  return SendCommand(ref.watch(connectionRepositoryProvider));
});
