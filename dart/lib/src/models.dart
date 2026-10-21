class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);

  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
      );
}

class Citation {
  final String documentName;
  final String excerpt;
  final double confidence;

  Citation({
    required this.documentName,
    required this.excerpt,
    required this.confidence,
  });

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        documentName: json['documentName'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );
}

class ChatChoice {
  final int index;
  final ChatMessage message;
  final String? finishReason;

  ChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory ChatChoice.fromJson(Map<String, dynamic> json) => ChatChoice(
        index: json['index'] as int? ?? 0,
        message: ChatMessage.fromJson(
            (json['message'] as Map<String, dynamic>?) ?? {}),
        finishReason: json['finish_reason'] as String?,
      );
}

class ChatCompletionRequest {
  final List<ChatMessage>? messages;
  final String? query;
  final bool stream;
  final double? temperature;
  final int? maxTokens;
  final String? projectId;

  ChatCompletionRequest({
    this.messages,
    this.query,
    this.stream = false,
    this.temperature,
    this.maxTokens,
    this.projectId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'stream': stream,
    };
    if (messages != null) {
      map['messages'] = messages!.map((m) => m.toJson()).toList();
    }
    if (query != null) {
      map['query'] = query;
    }
    if (temperature != null) {
      map['temperature'] = temperature;
    }
    if (maxTokens != null) {
      map['max_tokens'] = maxTokens;
    }
    if (projectId != null) {
      map['projectId'] = projectId;
    }
    return map;
  }
}

class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatChoice> choices;
  final Citation? citation;

  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.citation,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    final choicesList = (json['choices'] as List<dynamic>?) ?? [];
    return ChatCompletionResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? 'chat.completion',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? 'unii-rag',
      choices: choicesList
          .map((c) => ChatChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      citation: json['citation'] != null
          ? Citation.fromJson(json['citation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StreamDelta {
  final String? role;
  final String? content;

  StreamDelta({this.role, this.content});

  factory StreamDelta.fromJson(Map<String, dynamic> json) => StreamDelta(
        role: json['role'] as String?,
        content: json['content'] as String?,
      );
}

class StreamChoice {
  final int index;
  final StreamDelta delta;
  final String? finishReason;

  StreamChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  factory StreamChoice.fromJson(Map<String, dynamic> json) => StreamChoice(
        index: json['index'] as int? ?? 0,
        delta: StreamDelta.fromJson(
            (json['delta'] as Map<String, dynamic>?) ?? {}),
        finishReason: json['finish_reason'] as String?,
      );
}

class ChatCompletionChunk {
  final String id;
  final String object;
  final List<StreamChoice> choices;

  ChatCompletionChunk({
    required this.id,
    required this.object,
    required this.choices,
  });

  factory ChatCompletionChunk.fromJson(Map<String, dynamic> json) {
    final list = (json['choices'] as List<dynamic>?) ?? [];
    return ChatCompletionChunk(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? 'chat.completion.chunk',
      choices: list
          .map((c) => StreamChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AuthVerificationResponse {
  final String status;
  final String keyId;
  final String keyName;
  final String organizationId;
  final String projectId;

  AuthVerificationResponse({
    required this.status,
    required this.keyId,
    required this.keyName,
    required this.organizationId,
    required this.projectId,
  });

  factory AuthVerificationResponse.fromJson(Map<String, dynamic> json) =>
      AuthVerificationResponse(
        status: json['status'] as String? ?? '',
        keyId: json['keyId'] as String? ?? '',
        keyName: json['keyName'] as String? ?? '',
        organizationId: json['organizationId'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
      );
}
