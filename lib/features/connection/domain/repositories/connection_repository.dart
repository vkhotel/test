import '../../../../core/utils/result.dart';
import '../entities/connection_info.dart';
import '../entities/discovered_host.dart';

/// The single gateway between the app and "the desktop receiver", covering
/// discovery, connection lifecycle, outgoing commands, and the aggregated
/// status stream the UI observes. Everything below the interface (sockets,
/// UDP broadcasts, shared prefs for the last-used host) is an implementation
/// detail owned by `data/repositories/connection_repository_impl.dart`.
abstract class ConnectionRepository {
  /// A broadcast stream that immediately replays the current [ConnectionInfo]
  /// to new listeners, then emits again on every change.
  Stream<ConnectionInfo> watchConnectionInfo();

  /// Broadcasts a UDP discovery request and streams hosts as they respond,
  /// closing itself after [AppConstants.discoveryTimeout].
  Stream<List<DiscoveredHost>> discoverHosts();

  Future<Result<void>> connect(String ip, int port, {String? hostName});

  Future<void> disconnect();

  /// Sends an already-serialized command payload (see `MouseCommand.toJson`)
  /// over the active WebSocket connection.
  Future<Result<void>> sendCommand(Map<String, dynamic> payload);

  /// Best-effort local IP lookup, used to display "Device IP" even before a
  /// connection is made.
  Future<String?> getLocalIpAddress();

  /// The most recently connected-to host, persisted across app restarts, or
  /// `null` if AeroTouch has never successfully connected to anything yet.
  /// Used to offer a one-tap "reconnect" instead of forcing a fresh scan.
  DiscoveredHost? get lastKnownHost;

  /// Called by the mouse-control feature roughly once a second while active,
  /// so the Home screen's FPS stat reflects the real achieved sample rate.
  void reportFps(double fps);

  /// Mirrors the "Reconnect automatically" Settings toggle onto the
  /// underlying socket datasource.
  void setAutoReconnect(bool enabled);

  void dispose();
}
