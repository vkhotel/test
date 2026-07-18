import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/discovered_host_model.dart';

/// Finds AeroTouch-compatible desktop receivers on the current LAN by
/// broadcasting a small UDP "discover" packet on [AppConstants.discoveryPort]
/// and collecting every "announce" reply that arrives within the timeout.
///
/// This has no Flutter dependency at all (pure `dart:io`), so it's trivial
/// to unit test or reuse outside of a widget tree.
class UdpDiscoveryDataSource {
  RawDatagramSocket? _socket;

  /// Emits the growing list of discovered hosts as replies arrive, then
  /// closes the stream once [timeout] elapses.
  Stream<List<DiscoveredHostModel>> discover({
    Duration timeout = AppConstants.discoveryTimeout,
  }) {
    late final StreamController<List<DiscoveredHostModel>> controller;
    final found = <String, DiscoveredHostModel>{};
    Timer? timeoutTimer;

    Future<void> start() async {
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.broadcastEnabled = true;
        _socket = socket;

        final requestPayload = utf8.encode(jsonEncode({'type': 'aerotouch_discover'}));
        socket.send(requestPayload, InternetAddress('255.255.255.255'), AppConstants.discoveryPort);

        socket.listen((event) {
          if (event != RawSocketEvent.read) return;
          final datagram = socket.receive();
          if (datagram == null) return;

          try {
            final decoded = jsonDecode(utf8.decode(datagram.data));
            if (decoded is! Map<String, dynamic>) return;
            if (decoded['type'] != 'aerotouch_announce') return;

            final host = DiscoveredHostModel.fromAnnounce(decoded, datagram.address.address);
            found['${host.ip}:${host.port}'] = host;
            if (!controller.isClosed) {
              controller.add(found.values.toList(growable: false));
            }
          } catch (_) {
            // Malformed / foreign UDP traffic on this port - ignore it.
          }
        });

        timeoutTimer = Timer(timeout, () {
          socket.close();
          _socket = null;
          if (!controller.isClosed) unawaited(controller.close());
        });
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(DiscoveryException('Discovery socket failed: $e'));
          await controller.close();
        }
      }
    }

    controller = StreamController<List<DiscoveredHostModel>>(
      onListen: start,
      onCancel: () {
        timeoutTimer?.cancel();
        _socket?.close();
        _socket = null;
      },
    );

    return controller.stream;
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }
}
