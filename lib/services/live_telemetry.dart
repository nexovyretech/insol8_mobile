import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:insol8_mobile/constants/api_config.dart';
import 'package:insol8_mobile/services/api_client.dart';

/// One telemetry batch pushed by the backend for a watched dryer. Readings are
/// oldest first; any sensor value may be missing from a reading.
class LiveTelemetryBatch {
  const LiveTelemetryBatch({
    required this.deviceId,
    required this.sessionId,
    required this.readings,
  });

  factory LiveTelemetryBatch.fromJson(Map<String, dynamic> json) =>
      LiveTelemetryBatch(
        deviceId: json['deviceId'] as String,
        sessionId: json['sessionId'] as String?,
        readings: (json['readings'] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      );

  final String deviceId;
  final String? sessionId;
  final List<Map<String, dynamic>> readings;

  /// The newest chamber temperature in the batch, if any reading has one.
  double? get latestChamberTemperature => _latest('temperatureC');

  /// The newest energy saved (kWh, cumulative for the job) in the batch.
  double? get latestEnergySavedKwh => _latest('energySavedKWh');

  /// The newest thermal battery charge as a percentage; the dryer sends it as
  /// `standalone_state_of_charge`, a fraction from 0 to 1.
  double? get latestThermalChargePercent {
    final charge = _latest('standalone_state_of_charge');
    return charge == null ? null : (charge * 1000).round() / 10;
  }

  double? _latest(String field) => readings.reversed
      .map((reading) => (reading[field] as num?)?.toDouble())
      .whereType<double>()
      .firstOrNull;
}

/// Live telemetry for one dryer at a time.
abstract interface class LiveTelemetrySource {
  /// Batches for [deviceId] as they arrive (about every 30 s). Cancelling the
  /// subscription closes the connection.
  Stream<LiveTelemetryBatch> watch(String deviceId);
}

/// Connects to the live WebSocket API with the user's Cognito token and
/// subscribes to one device.
class WebSocketLiveTelemetry implements LiveTelemetrySource {
  WebSocketLiveTelemetry({
    this.url = ApiSettings.liveUrl,
    Future<String> Function()? accessToken,
    WebSocketChannel Function(Uri uri)? connect,
  }) : _accessToken = accessToken ?? cognitoAccessToken,
       _connect = connect ?? WebSocketChannel.connect;

  final String url;
  final Future<String> Function() _accessToken;
  final WebSocketChannel Function(Uri uri) _connect;

  @override
  Stream<LiveTelemetryBatch> watch(String deviceId) {
    WebSocketChannel? channel;
    late final StreamController<LiveTelemetryBatch> controller;
    controller = StreamController<LiveTelemetryBatch>(
      onListen: () async {
        try {
          final token = await _accessToken();
          // Mobile WebSocket clients cannot set headers, so the API reads the
          // token from the query string.
          channel = _connect(
            Uri.parse(url).replace(queryParameters: {'token': token}),
          );
          await channel!.ready;
          channel!.sink.add(
            jsonEncode({'action': 'subscribe', 'deviceId': deviceId}),
          );
          await for (final message in channel!.stream) {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            if (json['type'] == 'telemetry') {
              controller.add(LiveTelemetryBatch.fromJson(json));
            } else if (json['type'] == 'error') {
              controller.addError(
                ApiException(
                  0,
                  json['code'] as String? ?? 'ERROR',
                  json['message'] as String? ?? 'Live updates failed.',
                ),
              );
            }
          }
        } on Object catch (error) {
          if (!controller.isClosed) controller.addError(error);
        }
        if (!controller.isClosed) await controller.close();
      },
      onCancel: () => channel?.sink.close(),
    );
    return controller.stream;
  }
}
