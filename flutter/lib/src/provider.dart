import 'package:flutter/widgets.dart';
import 'controller.dart';

class UniiProvider extends InheritedNotifier<UniiController> {
  final UniiController controller;

  UniiProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, notifier: controller, child: child);

  static UniiController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UniiProvider>();
    assert(provider != null, 'No UniiProvider found in context');
    return provider!.controller;
  }

  static UniiController? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UniiProvider>();
    return provider?.controller;
  }
}

extension UniiContextExtension on BuildContext {
  UniiController get unii => UniiProvider.of(this);
}
