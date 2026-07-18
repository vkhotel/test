import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Best-effort local network info (this phone's IP, and the WiFi network
/// name it's on) used to populate the "Device IP" / "Connection Method"
/// stats on the Home screen. Every call degrades gracefully to `null`
/// instead of throwing, since none of this is required for the app to work.
class NetworkInfoDataSource {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<String?> getLocalIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (_) {
      return null;
    }
  }

  /// Reading the WiFi SSID requires location permission on Android 8+.
  /// This requests it once (if not already decided) but never blocks the
  /// caller waiting on a user decision beyond that single prompt.
  Future<String?> getWifiName() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        await Permission.locationWhenInUse.request();
      }
      final rawName = await _networkInfo.getWifiName();
      return rawName?.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }
}
