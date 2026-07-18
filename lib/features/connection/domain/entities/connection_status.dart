/// Lifecycle states of the link to the desktop receiver.
enum ConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  reconnecting,
  error;

  bool get isActive => this == ConnectionStatus.connected;

  String get label => switch (this) {
        ConnectionStatus.disconnected => 'Disconnected',
        ConnectionStatus.discovering => 'Discovering',
        ConnectionStatus.connecting => 'Connecting',
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.reconnecting => 'Reconnecting',
        ConnectionStatus.error => 'Connection Error',
      };
}
