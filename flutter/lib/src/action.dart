import 'dart:async';
import 'package:flutter/widgets.dart';

enum ActionStatus {
  idle,
  executing,
  complete,
  error,
}

class UniiActionRenderProps {
  final Map<String, dynamic> args;
  final dynamic result;
  final ActionStatus status;
  final Object? error;
  final Future<dynamic> Function([Map<String, dynamic>? overrideArgs]) execute;

  const UniiActionRenderProps({
    required this.args,
    this.result,
    required this.status,
    this.error,
    required this.execute,
  });
}

class UniiActionConfig {
  final String name;
  final String description;
  final Map<String, dynamic>? parameters;
  final Future<dynamic> Function(Map<String, dynamic> args)? handler;
  final Widget Function(BuildContext context, UniiActionRenderProps props)? render;

  // Screen and component lifecycles
  final void Function()? onBeforeMount;
  final void Function()? onAfterMount;
  final void Function()? onBeforeUnmount;
  final void Function()? onAfterUnmount;

  // Execution lifecycles
  final FutureOr<bool?> Function(Map<String, dynamic> args)? onBeforeExecute;
  final void Function(dynamic result, Map<String, dynamic> args)? onAfterExecute;
  final void Function(Object error, Map<String, dynamic> args)? onError;

  const UniiActionConfig({
    required this.name,
    required this.description,
    this.parameters,
    this.handler,
    this.render,
    this.onBeforeMount,
    this.onAfterMount,
    this.onBeforeUnmount,
    this.onAfterUnmount,
    this.onBeforeExecute,
    this.onAfterExecute,
    this.onError,
  });
}
