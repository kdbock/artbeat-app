import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 2),
      responseTimeout: const Duration(minutes: 1),
    );
