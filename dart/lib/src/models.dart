class ToolCallFunction {
  final String name;
  final String arguments;

  ToolCallFunction({required this.name, required this.arguments});

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) =>
      ToolCallFunction(
        name: json['name'] as String? ?? '',
        arguments: json['arguments'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };
}

class ToolCall {
  final String id;
  final String type;
  final ToolCallFunction function;

  ToolCall({
    required this.id,
    this.type = 'function',
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'function',
        function: ToolCallFunction.fromJson(
            (json['function'] as Map<String, dynamic>?) ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function.toJson(),
      };
}

class FrontendToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic>? parameters;

  FrontendToolDefinition({
    required this.name,
    required this.description,
    this.parameters,
  });

  factory FrontendToolDefinition.fromJson(Map<String, dynamic> json) =>
      FrontendToolDefinition(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        parameters: json['parameters'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
    };
    if (parameters != null) {
      map['parameters'] = parameters;
    }
    return map;
  }
}

class ChatMessage {
  final String role;
  final String content;
  final List<ToolCall>? toolCalls;

  ChatMessage({
    required this.role,
    required this.content,
    this.toolCalls,
  });

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content, [List<ToolCall>? toolCalls]) =>
      ChatMessage(role: 'assistant', content: content, toolCalls: toolCalls);

  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (toolCalls != null) {
      map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }
    return map;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTools = json['tool_calls'] as List<dynamic>?;
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      toolCalls: rawTools
          ?.map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
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
  final List<FrontendToolDefinition>? frontendTools;
  final List<FrontendToolDefinition>? tools;

  ChatCompletionRequest({
    this.messages,
    this.query,
    this.stream = false,
    this.temperature,
    this.maxTokens,
    this.projectId,
    this.frontendTools,
    this.tools,
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
    if (frontendTools != null) {
      map['frontendTools'] = frontendTools!.map((t) => t.toJson()).toList();
    }
    if (tools != null) {
      map['tools'] = tools!.map((t) => t.toJson()).toList();
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
  final List<ToolCall>? toolCalls;

  StreamDelta({this.role, this.content, this.toolCalls});

  factory StreamDelta.fromJson(Map<String, dynamic> json) {
    final rawTools = json['tool_calls'] as List<dynamic>?;
    return StreamDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
      toolCalls: rawTools
          ?.map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
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
