import 'package:flutter/widgets.dart';
import 'action.dart';
import 'controller.dart';
import 'provider.dart';

class UniiAction extends StatefulWidget {
  final UniiActionConfig config;
  final Widget child;

  const UniiAction({
    Key? key,
    required this.config,
    required this.child,
  }) : super(key: key);

  @override
  State<UniiAction> createState() => _UniiActionState();
}

class _UniiActionState extends State<UniiAction> {
  UniiController? _controller;

  @override
  void initState() {
    super.initState();
    widget.config.onBeforeMount?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.config.onAfterMount?.call();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = UniiProvider.maybeOf(context);
    if (_controller != newController) {
      _controller?.unregisterAction(widget.config.name);
      _controller = newController;
      _controller?.registerAction(widget.config);
    }
  }

  @override
  void didUpdateWidget(covariant UniiAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.name != widget.config.name) {
      _controller?.unregisterAction(oldWidget.config.name);
      _controller?.registerAction(widget.config);
    }
  }

  @override
  void dispose() {
    widget.config.onBeforeUnmount?.call();
    _controller?.unregisterAction(widget.config.name);
    widget.config.onAfterUnmount?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
