import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:unii/unii.dart';
import 'action.dart';

class UniiController extends ChangeNotifier {
  final UniiClient client;
  final bool stream;
  final void Function(String name, Map<String, dynamic> args, dynamic result)? onActionExecute;

  List<ChatMessage> _messages;
  bool _isLoading = false;
  final Map<String, UniiActionConfig> _actions = {};

  UniiController({
    required this.client,
    List<ChatMessage>? initialMessages,
    this.stream = true,
    this.onActionExecute,
  }) : _messages = initialMessages != null ? List.from(initialMessages) : [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  void registerAction(UniiActionConfig action) {
    _actions[action.name] = action;
    notifyListeners();
  }

  void unregisterAction(String name) {
    if (_actions.remove(name) != null) {
      notifyListeners();
    }
  }

  UniiActionConfig? getAction(String name) => _actions[name];

  List<FrontendToolDefinition> getActiveTools() {
    return _actions.values
        .map(
          (a) => FrontendToolDefinition(
            name: a.name,
            description: a.description,
            parameters: a.parameters,
          ),
        )
        .toList();
  }

  Future<dynamic> executeAction(String name, Map<String, dynamic> args) async {
    final action = _actions[name];
    if (action == null) {
      throw StateError('Action "$name" is not registered on current screen.');
    }

    if (action.onBeforeExecute != null) {
      final canProceed = await action.onBeforeExecute!(args);
      if (canProceed == false) {
        return null;
      }
    }

    try {
      dynamic result;
      if (action.handler != null) {
        result = await action.handler!(args);
      }

      action.onAfterExecute?.call(result, args);
      onActionExecute?.call(name, args, result);
      return result;
    } catch (error) {
      action.onError?.call(error, args);
      rethrow;
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final userMsg = ChatMessage.user(trimmed);
    _messages = [..._messages, userMsg];
    _isLoading = true;
    notifyListeners();

    try {
      final activeTools = getActiveTools();
      final request = ChatCompletionRequest(
        messages: _messages,
        stream: stream,
        frontendTools: activeTools.isNotEmpty ? activeTools : null,
      );

      if (stream) {
        String accumulatedContent = '';
        final List<ToolCall> accumulatedToolCalls = [];

        _messages = [..._messages, ChatMessage.assistant('')];
        notifyListeners();

        await for (final chunk in client.streamChatCompletion(request)) {
          final choice = chunk.choices.isNotEmpty ? chunk.choices.first : null;
          if (choice == null) continue;

          final delta = choice.delta;
          if (delta.content != null) {
            accumulatedContent += delta.content!;
          }

          if (delta.toolCalls != null && delta.toolCalls!.isNotEmpty) {
            for (final tc in delta.toolCalls!) {
              final existingIdx = accumulatedToolCalls.indexWhere(
                (t) =>
                    (tc.id.isNotEmpty && t.id == tc.id) ||
                    (tc.function.name.isNotEmpty &&
                        t.function.name == tc.function.name),
              );

              if (existingIdx >= 0) {
                final existing = accumulatedToolCalls[existingIdx];
                accumulatedToolCalls[existingIdx] = ToolCall(
                  id: existing.id,
                  type: existing.type,
                  function: ToolCallFunction(
                    name: existing.function.name,
                    arguments:
                        existing.function.arguments + tc.function.arguments,
                  ),
                );
              } else {
                accumulatedToolCalls.add(tc);
              }
            }
          }

          _messages = [
            ..._messages.sublist(0, _messages.length - 1),
            ChatMessage(
              role: 'assistant',
              content: accumulatedContent,
              toolCalls: accumulatedToolCalls.isNotEmpty
                  ? List.from(accumulatedToolCalls)
                  : null,
            ),
          ];
          notifyListeners();
        }

        // Execute accumulated tool calls
        for (final toolCall in accumulatedToolCalls) {
          final toolName = toolCall.function.name;
          Map<String, dynamic> parsedArgs = {};
          try {
            parsedArgs = jsonDecode(toolCall.function.arguments)
                as Map<String, dynamic>;
          } catch (_) {}

          if (_actions.containsKey(toolName)) {
            await executeAction(toolName, parsedArgs);
          }
        }
      } else {
        final response = await client.createChatCompletion(request);
        final choice =
            response.choices.isNotEmpty ? response.choices.first : null;
        if (choice != null) {
          _messages = [..._messages, choice.message];
          notifyListeners();

          if (choice.message.toolCalls != null) {
            for (final toolCall in choice.message.toolCalls!) {
              Map<String, dynamic> parsedArgs = {};
              try {
                parsedArgs = jsonDecode(toolCall.function.arguments)
                    as Map<String, dynamic>;
              } catch (_) {}

              if (_actions.containsKey(toolCall.function.name)) {
                await executeAction(toolCall.function.name, parsedArgs);
              }
            }
          }
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
