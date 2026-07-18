import 'package:equatable/equatable.dart';

/// A desktop receiver found on the local network via UDP broadcast discovery.
class DiscoveredHost extends Equatable {
  const DiscoveredHost({
    required this.ip,
    required this.port,
    required this.name,
  });

  final String ip;
  final int port;
  final String name;

  @override
  List<Object?> get props => [ip, port, name];

  @override
  String toString() => '$name ($ip:$port)';
}
