import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unii/unii.dart';
import 'action.dart';
import 'provider.dart';

class UniiActionRenderer extends StatefulWidget {
  final ToolCall toolCall;
  final dynamic initialResult;

  const UniiActionRenderer({
    Key? key,
    required this.toolCall,
    this.initialResult,
  }) : super(key: key);

  @override
  State<UniiActionRenderer> createState() => _UniiActionRendererState();
}

class _UniiActionRendererState extends State<UniiActionRenderer> {
  late ActionStatus _status;
  dynamic _result;
  Object? _error;
  late Map<String, dynamic> _parsedArgs;

  @override
  void initState() {
    super.initState();
    _status = widget.initialResult != null
        ? ActionStatus.complete
        : ActionStatus.idle;
    _result = widget.initialResult;
    _parseArgs();
  }

  @override
  void didUpdateWidget(covariant UniiActionRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolCall.function.arguments !=
        widget.toolCall.function.arguments) {
      _parseArgs();
    }
  }

  void _parseArgs() {
    try {
      _parsedArgs = jsonDecode(widget.toolCall.function.arguments)
          as Map<String, dynamic>;
    } catch (_) {
      _parsedArgs = {};
    }
  }

  Future<dynamic> _execute([Map<String, dynamic>? overrideArgs]) async {
    setState(() {
      _status = ActionStatus.executing;
      _error = null;
    });

    try {
      final controller = UniiProvider.of(context);
      final mergedArgs = {..._parsedArgs, ...(overrideArgs ?? {})};
      final res = await controller.executeAction(
        widget.toolCall.function.name,
        mergedArgs,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _status = ActionStatus.complete;
        });
      }
      return res;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _status = ActionStatus.error;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = UniiProvider.maybeOf(context);
    final action = controller?.getAction(widget.toolCall.function.name);

    final props = UniiActionRenderProps(
      args: _parsedArgs,
      result: _result,
      status: _status,
      error: _error,
      execute: _execute,
    );

    if (action?.render != null) {
      return action!.render!(context, props);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Action: ${widget.toolCall.function.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
                fontSize: 13.0,
              ),
            ),
            if (_parsedArgs.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                'Args: $_parsedArgs',
                style: const TextStyle(fontSize: 12.0, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8.0),
            if (_status == ActionStatus.idle)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _execute,
                  child: const Text('Execute'),
                ),
              )
            else if (_status == ActionStatus.executing)
              const Row(
                children: [
                  SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                  SizedBox(width: 8.0),
                  Text('Executing...', style: TextStyle(fontSize: 12.0)),
                ],
              )
            else if (_status == ActionStatus.complete)
              Text(
                '✓ Completed ${_result != null ? "($_result)" : ""}',
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.0,
                ),
              )
            else if (_status == ActionStatus.error)
              Text(
                '✗ Error: $_error',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
