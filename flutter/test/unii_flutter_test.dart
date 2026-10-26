import 'package:flutter_test/flutter_test.dart';
import 'package:unii_flutter/unii_flutter.dart';

void main() {
  group('Unii Flutter SDK', () {
    test('UniiController registers and executes actions with lifecycles', () async {
      bool beforeRan = false;
      bool handlerRan = false;
      bool afterRan = false;

      final config = UniiActionConfig(
        name: 'calculate_discount',
        description: 'Calculates discount on total price',
        onBeforeExecute: (args) {
          beforeRan = true;
          return true;
        },
        handler: (args) async {
          handlerRan = true;
          final price = (args['price'] as num).toDouble();
          return price * 0.8;
        },
        onAfterExecute: (result, args) {
          afterRan = true;
          expect(result, 80.0);
          expect(args['price'], 100);
        },
      );

      final client = UniiClient(apiKey: 'dummy_key');
      final controller = UniiController(client: client, stream: false);

      controller.registerAction(config);
      expect(controller.getAction('calculate_discount'), equals(config));

      final tools = controller.getActiveTools();
      expect(tools.length, 1);
      expect(tools.first.name, 'calculate_discount');

      final result = await controller.executeAction('calculate_discount', {'price': 100});

      expect(beforeRan, isTrue);
      expect(handlerRan, isTrue);
      expect(afterRan, isTrue);
      expect(result, 80.0);
    });

    test('onBeforeExecute returning false cancels execution', () async {
      bool handlerRan = false;

      final config = UniiActionConfig(
        name: 'destructive_action',
        description: 'Deletes record',
        onBeforeExecute: (args) => false,
        handler: (args) async {
          handlerRan = true;
          return 'done';
        },
      );

      final client = UniiClient(apiKey: 'dummy_key');
      final controller = UniiController(client: client);
      controller.registerAction(config);

      final result = await controller.executeAction('destructive_action', {});
      expect(result, isNull);
      expect(handlerRan, isFalse);
    });

    test('onError lifecycle handles exceptions', () async {
      bool errorHandled = false;

      final config = UniiActionConfig(
        name: 'failing_action',
        description: 'Fails deliberately',
        handler: (args) async {
          throw Exception('Network unreachable');
        },
        onError: (err, args) {
          errorHandled = true;
          expect(err.toString(), contains('Network unreachable'));
        },
      );

      final client = UniiClient(apiKey: 'dummy_key');
      final controller = UniiController(client: client);
      controller.registerAction(config);

      expect(
        () async => await controller.executeAction('failing_action', {}),
        throwsA(isA<Exception>()),
      );
      expect(errorHandled, isTrue);
    });

    test('unregisterAction removes action from active list', () {
      final config = UniiActionConfig(
        name: 'test_action',
        description: 'Simple action',
      );

      final client = UniiClient(apiKey: 'dummy_key');
      final controller = UniiController(client: client);
      controller.registerAction(config);
      expect(controller.getAction('test_action'), isNotNull);

      controller.unregisterAction('test_action');
      expect(controller.getAction('test_action'), isNull);
      expect(controller.getActiveTools().isEmpty, isTrue);
    });
  });
}
