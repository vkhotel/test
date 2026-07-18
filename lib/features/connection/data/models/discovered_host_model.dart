import '../../domain/entities/discovered_host.dart';

/// [DiscoveredHost] plus JSON parsing for the UDP discovery announce packet.
///
/// Expected announce payload from the desktop receiver:
/// ```json
/// { "type": "aerotouch_announce", "name": "Alex's PC", "port": 58712 }
/// ```
/// The sender's IP is taken from the UDP datagram itself, not the payload.
class DiscoveredHostModel extends DiscoveredHost {
  const DiscoveredHostModel({
    required super.ip,
    required super.port,
    required super.name,
  });

  factory DiscoveredHostModel.fromAnnounce(Map<String, dynamic> json, String senderIp) {
    return DiscoveredHostModel(
      ip: senderIp,
      port: (json['port'] as num?)?.toInt() ?? 58712,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unnamed PC',
    );
  }
}
