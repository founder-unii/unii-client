class UniiApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  UniiApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return 'UniiApiException ($statusCode): $message - $details';
    }
    return 'UniiApiException ($statusCode): $message';
  }
}
