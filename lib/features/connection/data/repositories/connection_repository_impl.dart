import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/battery_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/connection_info.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/discovered_host.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/network_info_datasource.dart';
import '../datasources/udp_discovery_datasource.dart';
import '../datasources/websocket_datasource.dart';

/// Aggregates the WebSocket link, LAN discovery, local network info, and the
/// phone's battery into the single [ConnectionInfo] stream the rest of the
/// app observes. This is the only class in the feature that touches more
/// than one datasource - exactly the Repository pattern's job.
class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required WebSocketDataSource webSocketDataSource,
    required UdpDiscoveryDataSource discoveryDataSource,
    required NetworkInfoDataSource networkInfoDataSource,
    required BatteryService batteryService,
    required SharedPreferences prefs,
  })  : _ws = webSocketDataSource,
        _discovery = discoveryDataSource,
        _networkInfo = networkInfoDataSource,
        _battery = batteryService,
        _prefs = prefs {
    _loadLastHost();
    _wireWebSocketEvents();
    unawaited(_refreshLocalNetworkInfo());
    _startBatteryPolling();
  }

  final WebSocketDataSource _ws;
  final UdpDiscoveryDataSource _discovery;
  final NetworkInfoDataSource _networkInfo;
  final BatteryService _battery;
  final SharedPreferences _prefs;

  ConnectionInfo _info = ConnectionInfo.initial();
  final StreamController<ConnectionInfo> _infoController =
      StreamController<ConnectionInfo>.broadcast();

  StreamSubscription<ConnectionStatus>? _statusSub;
  StreamSubscription<int>? _latencySub;
  Timer? _batteryTimer;

  DiscoveredHost? _lastKnownHost;

  @override
  DiscoveredHost? get lastKnownHost => _lastKnownHost;

  // --- Aggregated status stream --------------------------------------------

  @override
  Stream<ConnectionInfo> watchConnectionInfo() async* {
    yield _info;
    yield* _infoController.stream;
  }

  void _emit() {
    if (!_infoController.isClosed) _infoController.add(_info);
  }

  void _wireWebSocketEvents() {
    _statusSub = _ws.statusStream.listen((status) {
      _info = _info.copyWith(status: status, clearError: status != ConnectionStatus.error);
      _emit();
    });
    _latencySub = _ws.latencyStream.listen((latencyMs) {
      _info = _info.copyWith(latencyMs: latencyMs);
      _emit();
    });
  }

  Future<void> _refreshLocalNetworkInfo() async {
    final ip = await _networkInfo.getLocalIpAddress();
    final wifiName = await _networkInfo.getWifiName();
    _info = _info.copyWith(localIp: ip, wifiName: wifiName);
    _emit();
  }

  void _startBatteryPolling() {
    unawaited(_pollBatteryOnce());
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollBatteryOnce());
  }

  Future<void> _pollBatteryOnce() async {
    final level = await _battery.currentLevel();
    if (level >= 0) {
      _info = _info.copyWith(batteryLevel: level);
      _emit();
    }
  }

  // --- Last-known-host persistence -----------------------------------------

  void _loadLastHost() {
    final raw = _prefs.getString(AppConstants.prefsLastHostKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _lastKnownHost = DiscoveredHost(
        ip: map['ip'] as String,
        port: (map['port'] as num).toInt(),
        name: (map['name'] as String?) ?? 'Desktop PC',
      );
    } catch (_) {
      // Corrupt or old-format entry - safe to ignore, discovery will refill it.
    }
  }

  Future<void> _persistHost(DiscoveredHost host) async {
    _lastKnownHost = host;
    await _prefs.setString(
      AppConstants.prefsLastHostKey,
      jsonEncode({'ip': host.ip, 'port': host.port, 'name': host.name}),
    );
  }

  // --- Discovery --------------------------------------------------------------

  @override
  Stream<List<DiscoveredHost>> discoverHosts() {
    _info = _info.copyWith(status: ConnectionStatus.discovering);
    _emit();

    final controller = StreamController<List<DiscoveredHost>>();
    final subscription = _discovery.discover().listen(
      (hosts) => controller.add(hosts.cast<DiscoveredHost>()),
      onError: controller.addError,
      onDone: () {
        // If the scan finished without a connection being made in the
        // meantime, fall back to Disconnected instead of leaving the UI
        // stuck showing "Discovering" forever.
        if (_info.status == ConnectionStatus.discovering) {
          _info = _info.copyWith(status: ConnectionStatus.disconnected);
          _emit();
        }
        unawaited(controller.close());
      },
    );
    controller.onCancel = subscription.cancel;
    return controller.stream;
  }

  // --- Connection lifecycle -----------------------------------------------

  @override
  Future<Result<void>> connect(String ip, int port, {String? hostName}) async {
    final succeeded = await _ws.connect(ip, port);
    if (!succeeded) {
      return const Result.failure(ConnectionFailure());
    }

    final resolvedName = hostName ?? (_lastKnownHost?.ip == ip ? _lastKnownHost!.name : 'Desktop PC');
    await _persistHost(DiscoveredHost(ip: ip, port: port, name: resolvedName));

    _info = _info.copyWith(hostIp: ip, hostPort: port, connectionMethod: 'Wi-Fi');
    _emit();
    return const Result.success(null);
  }

  @override
  Future<void> disconnect() async {
    await _ws.disconnect();
    _info = _info.copyWith(latencyMs: 0, fps: 0);
    _emit();
  }

  @override
  Future<Result<void>> sendCommand(Map<String, dynamic> payload) async {
    try {
      await _ws.send(payload);
      return const Result.success(null);
    } on SocketConnectException catch (e) {
      return Result.failure(SendFailure(e.message));
    } catch (e) {
      return Result.failure(SendFailure('$e'));
    }
  }

  @override
  Future<String?> getLocalIpAddress() => _networkInfo.getLocalIpAddress();

  @override
  void reportFps(double fps) {
    _info = _info.copyWith(fps: fps);
    _emit();
  }

  @override
  void setAutoReconnect(bool enabled) {
    _ws.autoReconnect = enabled;
  }

  @override
  void dispose() {
    unawaited(_statusSub?.cancel());
    unawaited(_latencySub?.cancel());
    _batteryTimer?.cancel();
    _ws.dispose();
    _discovery.dispose();
    unawaited(_infoController.close());
  }
}
