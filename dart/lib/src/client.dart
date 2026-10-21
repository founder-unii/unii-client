import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'errors.dart';
import 'models.dart';

class UniiClient {
  final String apiKey;
  final String baseUrl;
  final String? projectId;
  final http.Client _client;

  UniiClient({
    required this.apiKey,
    String baseUrl = 'http://localhost:8080',
    this.projectId,
    http.Client? httpClient,
  })  : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = httpClient ?? http.Client() {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('apiKey cannot be empty');
    }
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    return {
      'Authorization': 'Bearer $apiKey',
      'User-Agent': 'unii-dart-sdk/0.1.0',
      ...?extra,
    };
  }

  Future<AuthVerificationResponse> verifyAuth() async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/verify');
    final response = await _client.get(
      uri,
      headers: _headers({'Accept': 'application/json'}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UniiApiException(
        response.statusCode,
        'Auth verification failed',
        response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthVerificationResponse.fromJson(json);
  }

  Future<ChatCompletionResponse> createChatCompletion(
      ChatCompletionRequest request) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/completions');
    final bodyMap = request.toJson();
    bodyMap['stream'] = false;
    if (bodyMap['projectId'] == null && projectId != null) {
      bodyMap['projectId'] = projectId;
    }

    final response = await _client.post(
      uri,
      headers: _headers({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }),
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UniiApiException(
        response.statusCode,
        'Chat completion failed',
        response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatCompletionResponse.fromJson(json);
  }

  Stream<ChatCompletionChunk> streamChatCompletion(
      ChatCompletionRequest request) async* {
    final uri = Uri.parse('$baseUrl/api/v1/chat/completions');
    final bodyMap = request.toJson();
    bodyMap['stream'] = true;
    if (bodyMap['projectId'] == null && projectId != null) {
      bodyMap['projectId'] = projectId;
    }

    final httpRequest = http.Request('POST', uri)
      ..headers.addAll(_headers({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      }))
      ..body = jsonEncode(bodyMap);

    final streamedResponse = await _client.send(httpRequest);

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw UniiApiException(
        streamedResponse.statusCode,
        'Stream request failed',
        errorBody,
      );
    }

    String buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith(':')) {
          continue;
        }

        if (trimmed.startsWith('data:')) {
          final data = trimmed.substring(5).trim();
          if (data == '[DONE]') {
            return;
          }
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            yield ChatCompletionChunk.fromJson(json);
          } catch (_) {
            // ignore malformed frame
          }
        }
      }
    }
  }

  void close() {
    _client.close();
  }
}
