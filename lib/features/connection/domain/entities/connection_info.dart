import 'package:equatable/equatable.dart';

import 'connection_status.dart';

/// Everything the Home screen's "Device Status" section needs, aggregated
/// from the WebSocket link, LAN info, and the phone's own battery.
class ConnectionInfo extends Equatable {
  const ConnectionInfo({
    required this.status,
    this.hostIp,
    this.hostPort,
    this.connectionMethod = 'Wi-Fi',
    this.localIp,
    this.wifiName,
    this.batteryLevel,
    this.latencyMs = 0,
    this.fps = 0,
    this.errorMessage,
  });

  factory ConnectionInfo.initial() => const ConnectionInfo(status: ConnectionStatus.disconnected);

  final ConnectionStatus status;
  final String? hostIp;
  final int? hostPort;
  final String connectionMethod;
  final String? localIp;
  final String? wifiName;
  final int? batteryLevel;
  final int latencyMs;
  final double fps;
  final String? errorMessage;

  bool get isConnected => status == ConnectionStatus.connected;

  ConnectionInfo copyWith({
    ConnectionStatus? status,
    String? hostIp,
    int? hostPort,
    String? connectionMethod,
    String? localIp,
    String? wifiName,
    int? batteryLevel,
    int? latencyMs,
    double? fps,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConnectionInfo(
      status: status ?? this.status,
      hostIp: hostIp ?? this.hostIp,
      hostPort: hostPort ?? this.hostPort,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      localIp: localIp ?? this.localIp,
      wifiName: wifiName ?? this.wifiName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      latencyMs: latencyMs ?? this.latencyMs,
      fps: fps ?? this.fps,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        hostIp,
        hostPort,
        connectionMethod,
        localIp,
        wifiName,
        batteryLevel,
        latencyMs,
        fps,
        errorMessage,
      ];
}
