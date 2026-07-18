/// Base type for every recoverable error surfaced from the data layer.
///
/// Kept intentionally small: the UI generally only needs a human-readable
/// [message], while call sites that care about the exact cause can switch
/// on the concrete subtype.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'Could not reach the desktop receiver.']);
}

class DiscoveryFailure extends Failure {
  const DiscoveryFailure([super.message = 'No devices were found on this network.']);
}

class SendFailure extends Failure {
  const SendFailure([super.message = 'Message failed to send.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not read or write local storage.']);
}

class SensorFailure extends Failure {
  const SensorFailure([super.message = 'A required motion sensor is unavailable.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'A required permission was denied.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something unexpected went wrong.']);
}
