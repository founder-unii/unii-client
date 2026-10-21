import 'package:test/test.dart';
import 'package:unii/unii.dart';

void main() {
  group('Dart SDK Models & Client', () {
    test('ChatMessage json serialization', () {
      final msg = ChatMessage.user('Hello Dart');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello Dart');

      final json = msg.toJson();
      expect(json['role'], 'user');
      expect(json['content'], 'Hello Dart');

      final decoded = ChatMessage.fromJson(json);
      expect(decoded.role, 'user');
      expect(decoded.content, 'Hello Dart');
    });

    test('ChatCompletionRequest serialization', () {
      final req = ChatCompletionRequest(
        messages: [ChatMessage.user('Question')],
        temperature: 0.5,
        maxTokens: 256,
        projectId: 'project-xyz',
      );

      final json = req.toJson();
      expect(json['stream'], false);
      expect(json['temperature'], 0.5);
      expect(json['max_tokens'], 256);
      expect(json['projectId'], 'project-xyz');
      expect((json['messages'] as List).length, 1);
    });

    test('ChatCompletionResponse deserialization', () {
      final map = {
        'id': 'chatcmpl-dart-123',
        'object': 'chat.completion',
        'created': 1700000000,
        'model': 'unii-rag',
        'choices': [
          {
            'index': 0,
            'message': {
              'role': 'assistant',
              'content': 'Response from AI',
            },
            'finish_reason': 'stop',
          }
        ],
        'citation': {
          'documentName': 'dart_manual.pdf',
          'excerpt': 'Dart client docs',
          'confidence': 0.99,
        }
      };

      final response = ChatCompletionResponse.fromJson(map);
      expect(response.id, 'chatcmpl-dart-123');
      expect(response.choices.length, 1);
      expect(response.choices.first.message.content, 'Response from AI');
      expect(response.citation, isNotNull);
      expect(response.citation?.documentName, 'dart_manual.pdf');
      expect(response.citation?.confidence, 0.99);
    });

    test('AuthVerificationResponse deserialization', () {
      final map = {
        'status': 'authenticated',
        'keyId': 'key-dart',
        'keyName': 'mobile-app',
        'organizationId': 'org-1',
        'projectId': 'proj-1',
      };

      final auth = AuthVerificationResponse.fromJson(map);
      expect(auth.status, 'authenticated');
      expect(auth.keyId, 'key-dart');
      expect(auth.projectId, 'proj-1');
    });

    test('UniiClient rejects empty apiKey', () {
      expect(() => UniiClient(apiKey: ''), throwsArgumentError);
    });
  });
}
