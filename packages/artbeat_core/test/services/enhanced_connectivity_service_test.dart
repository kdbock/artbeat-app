import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService Tests', () {
    test('ConnectivityService initializes correctly', () {
      final service = ConnectivityService();
      expect(service, isNotNull);
    });

    test('ConnectivityService connectionStatus is available', () {
      final service = ConnectivityService();
      expect(service.connectionStatus, isNotNull);
    });

    test('ConnectivityService isConnected is accessible', () {
      final service = ConnectivityService();
      expect(service.isConnected, isA<bool>());
    });

    test('ConnectivityService can simulate connection changes', () {
      final service = ConnectivityService();

      // Test initial state (default is WiFi per implementation)
      expect(service.connectionStatus, equals(ConnectionStatus.wifi));
      expect(service.isConnected, isTrue);

      // Simulate a disconnection
      service.simulateConnectionChange(ConnectionStatus.none);
      expect(service.connectionStatus, equals(ConnectionStatus.none));
      expect(service.isConnected, isFalse);

      // Simulate mobile connection
      service.simulateConnectionChange(ConnectionStatus.mobile);
      expect(service.connectionStatus, equals(ConnectionStatus.mobile));
      expect(service.isConnected, isTrue);

      // Test getConnectionType() method
      expect(service.getConnectionType(), equals('Mobile Data'));
    });
  });
}
