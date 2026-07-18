import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/connection_info.dart';
import '../../domain/entities/discovered_host.dart';
import '../providers/connection_providers.dart';

/// Bridges [ConnectionRepository.watchConnectionInfo] into Riverpod state
/// and exposes the small set of actions the UI needs (connect, disconnect,
/// discover). All the actual networking logic lives in the data layer; this
/// class is intentionally thin.
class ConnectionNotifier extends Notifier<ConnectionInfo> {
  StreamSubscription<ConnectionInfo>? _sub;

  @override
  ConnectionInfo build() {
    final repository = ref.watch(connectionRepositoryProvider);
    _sub = repository.watchConnectionInfo().listen((info) => state = info);
    ref.onDispose(() {
      _sub?.cancel();
    });
    return ConnectionInfo.initial();
  }

  Stream<List<DiscoveredHost>> discoverHosts() {
    return ref.read(discoverHostsUseCaseProvider).call();
  }

  Future<Result<void>> connect(DiscoveredHost host) {
    return ref.read(connectToHostUseCaseProvider).call(host.ip, host.port, hostName: host.name);
  }

  Future<Result<void>> connectManual(String ip, int port) {
    return ref.read(connectToHostUseCaseProvider).call(ip, port);
  }

  Future<Result<void>> reconnectToLastHost() {
    final host = ref.read(connectionRepositoryProvider).lastKnownHost;
    if (host == null) {
      return Future<Result<void>>.value(
        const Result.failure(ConnectionFailure('No previously connected device to reconnect to.')),
      );
    }
    return connect(host);
  }

  Future<void> disconnect() {
    return ref.read(disconnectFromHostUseCaseProvider).call();
  }

  DiscoveredHost? get lastKnownHost => ref.read(connectionRepositoryProvider).lastKnownHost;
}

final connectionNotifierProvider = NotifierProvider<ConnectionNotifier, ConnectionInfo>(
  ConnectionNotifier.new,
);
