/// Base URL of the InSOL8 HTTP API (the `ApiEndpoint` output of the SAM stack).
/// Override per build with `--dart-define=INSOL8_API_URL=https://...`.
abstract final class ApiSettings {
  static const baseUrl = String.fromEnvironment(
    'INSOL8_API_URL',
    defaultValue: 'https://5q7gztfpb6.execute-api.ap-southeast-2.amazonaws.com',
  );

  /// Live telemetry WebSocket (the `LiveWebSocketUrl` output of the SAM stack).
  /// Override per build with `--dart-define=INSOL8_LIVE_URL=wss://...`.
  static const liveUrl = String.fromEnvironment(
    'INSOL8_LIVE_URL',
    defaultValue:
        'wss://tjjzjjdlpa.execute-api.ap-southeast-2.amazonaws.com/live',
  );

  static const requestTimeout = Duration(seconds: 15);
}
