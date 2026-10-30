import 'dart:async';
import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide ApiException;
import 'package:http/http.dart' as http;

import 'package:insol8_mobile/constants/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  /// 0 when the request never got an HTTP response (offline, timeout).
  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

/// Calls the InSOL8 HTTP API. Protected routes carry the Cognito access token,
/// which the API Gateway JWT authorizer verifies.
class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = ApiSettings.baseUrl,
    Future<String> Function()? accessToken,
  }) : _client = client ?? http.Client(),
       _tokenProvider = accessToken;

  final http.Client _client;
  final String baseUrl;

  /// Overrides the Cognito session lookup (tests).
  final Future<String> Function()? _tokenProvider;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) =>
      _object(_send('GET', path, authenticated: authenticated));

  /// For list routes such as `GET /devices`, whose `data` is an array.
  Future<List<Map<String, dynamic>>> getList(String path) async {
    final data = await _send('GET', path, authenticated: true);
    if (data is! List) {
      throw const ApiException(
        200,
        'BAD_RESPONSE',
        'Unexpected server response.',
      );
    }
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) => _object(_send('POST', path, body: body, authenticated: authenticated));

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _object(_send('PUT', path, body: body, authenticated: true));

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _object(_send('PATCH', path, body: body, authenticated: true));

  Future<Map<String, dynamic>> delete(String path) =>
      _object(_send('DELETE', path, authenticated: true));

  Future<Map<String, dynamic>> _object(Future<Object?> data) async =>
      (await data as Map<String, dynamic>?) ?? const {};

  /// Returns the response's `data`: an object, a list, or null.
  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['content-type'] = 'application/json';
    if (authenticated) {
      request.headers['authorization'] = 'Bearer ${await _accessToken()}';
    }
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(ApiSettings.requestTimeout),
      ).timeout(ApiSettings.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        0,
        'TIMEOUT',
        'The server took too long to respond.',
      );
    } on http.ClientException {
      throw const ApiException(
        0,
        'NETWORK',
        'Check your internet connection and try again.',
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        response.statusCode,
        'BAD_RESPONSE',
        'Unexpected server response.',
      );
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json['success'] == true) {
      return json['data'];
    }
    final error = json['error'] as Map<String, dynamic>?;
    throw ApiException(
      response.statusCode,
      error?['code'] as String? ??
          (response.statusCode == 401 ? 'UNAUTHORIZED' : 'ERROR'),
      error?['message'] as String? ?? 'Request failed.',
    );
  }

  Future<String> _accessToken() async {
    if (_tokenProvider != null) return _tokenProvider();
    return cognitoAccessToken();
  }
}

/// The signed-in user's Cognito access token, for the HTTP API and the live
/// WebSocket.
Future<String> cognitoAccessToken() async {
  final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
  return session.userPoolTokensResult.value.accessToken.raw;
}
