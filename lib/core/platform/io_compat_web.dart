class IOException implements Exception {
  const IOException([this.message]);

  final String? message;

  @override
  String toString() => message == null ? 'IOException' : 'IOException: $message';
}

class SocketException extends IOException {
  const SocketException([super.message]);
}
