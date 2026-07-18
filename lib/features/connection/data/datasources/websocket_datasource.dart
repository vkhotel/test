import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/connection_status.dart';

/// Owns the raw WebSocket connection to the desktop receiver.
///
/// Responsibilities:
///  * Opening/closing the socket and exposing its [ConnectionStatus].
///  * A `ping`/`pong` heartbeat every [AppConstants.heartbeatInterval] that
///    doubles as both a liveness check and the latency measurement shown on
///    the Home screen.
///  * Exponential-backoff auto-reconnect when the link drops unexpectedly
///    (never when the user explicitly disconnects).
///
/// This class never lets an exception escape a `Timer`/stream callback -
/// every failure path degrades to an emitted [ConnectionStatus.error] plus a
/// scheduled retry, so the app can never crash from a flaky network.
class WebSocketDataSource {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  String? _lastIp;
  int? _lastPort;
  bool autoReconnect = true;
  bool _manuallyDisconnected = false;
  int? _pendingPingSentAtMs;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<int> _latencyController = StreamController<int>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<int> get latencyStream => _latencyController.stream;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  /// Attempts to open a connection to [ip]:[port]. Returns `true` if the
  /// handshake succeeded. On failure the status stream already reflects
  /// [ConnectionStatus.error] and, if [autoReconnect] is on, background
  /// retries have started - callers don't need to retry manually.
  Future<bool> connect(String ip, int port) async {
    _manuallyDisconnected = false;
    _lastIp = ip;
    _lastPort = port;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    return _openChannel();
  }

  Future<bool> _openChannel() async {
    if (_lastIp == null || _lastPort == null) return false;
    _setStatus(
      _reconnectAttempts == 0 ? ConnectionStatus.connecting : ConnectionStatus.reconnecting,
    );

    try {
      final uri = Uri.parse('ws://$_lastIp:$_lastPort');
      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(AppConstants.connectTimeout);

      _channel = channel;
      _reconnectAttempts = 0;
      _setStatus(ConnectionStatus.connected);
      _startHeartbeat();

      _channelSub = channel.stream.listen(
        _handleIncoming,
        onDone: _handleDisconnected,
        onError: (Object _, StackTrace __) => _handleDisconnected(),
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      _setStatus(ConnectionStatus.error);
      _scheduleReconnect();
      return false;
    }
  }

  void _handleIncoming(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['type'] == 'pong') {
        final sentAt = _pendingPingSentAtMs;
        if (sentAt != null) {
          final rtt = DateTime.now().millisecondsSinceEpoch - sentAt;
          if (!_latencyController.isClosed) _latencyController.add(rtt);
        }
        _heartbeatTimeoutTimer?.cancel();
      }
    } catch (_) {
      // Malformed frame - ignore rather than tearing the connection down.
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(AppConstants.heartbeatInterval, (_) => _sendPing());
    _sendPing();
  }

  void _sendPing() {
    if (_channel == null) return;
    _pendingPingSentAtMs = DateTime.now().millisecondsSinceEpoch;
    _writeRaw({'type': 'ping', 'ts': _pendingPingSentAtMs});

    _heartbeatTimeoutTimer?.cancel();
    // No pong within the timeout window means the link is effectively dead
    // even if the OS hasn't reported the socket as closed yet.
    _heartbeatTimeoutTimer = Timer(AppConstants.heartbeatTimeout, _handleDisconnected);
  }

  /// Sends an application payload (mouse commands). Throws
  /// [SocketConnectException] if there is no active connection, so the
  /// repository can surface a `Result.failure` to the UI.
  Future<void> send(Map<String, dynamic> payload) async {
    if (_channel == null || _status != ConnectionStatus.connected) {
      throw const SocketConnectException('Not connected');
    }
    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      _handleDisconnected();
      throw SocketConnectException('Send failed: $e');
    }
  }

  /// Internal fire-and-forget write used for heartbeats, where there is no
  /// caller able to react to a thrown exception (Timer callbacks).
  void _writeRaw(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      _handleDisconnected();
    }
  }

  void _handleDisconnected() {
    if (_status == ConnectionStatus.disconnected) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimeoutTimer?.cancel();
    unawaited(_channelSub?.cancel());
    _channel = null;

    if (_manuallyDisconnected || !autoReconnect) {
      _setStatus(ConnectionStatus.disconnected);
      return;
    }

    _setStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected || !autoReconnect) return;
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      _setStatus(ConnectionStatus.disconnected);
      return;
    }
    _reconnectAttempts++;

    final delayMs = math.min(
      AppConstants.reconnectBaseDelay.inMilliseconds * math.pow(1.6, _reconnectAttempts - 1),
      AppConstants.reconnectMaxDelay.inMilliseconds.toDouble(),
    ).round();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_manuallyDisconnected) unawaited(_openChannel());
    });
  }

  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimeoutTimer?.cancel();
    await _channelSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  void dispose() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimeoutTimer?.cancel();
    unawaited(_channelSub?.cancel());
    unawaited(_channel?.sink.close());
    unawaited(_statusController.close());
    unawaited(_latencyController.close());
  }
}
