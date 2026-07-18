/// Exceptions thrown by the data layer (datasources). Repositories catch
/// these and translate them into a [Failure] before they ever reach domain
/// or presentation code.
class SocketConnectException implements Exception {
  final String message;
  const SocketConnectException([this.message = 'Socket connection failed']);
  @override
  String toString() => message;
}

class DiscoveryException implements Exception {
  final String message;
  const DiscoveryException([this.message = 'Discovery failed']);
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache read/write failed']);
  @override
  String toString() => message;
}
