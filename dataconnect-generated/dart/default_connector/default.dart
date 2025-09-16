library default_connector;

import 'package:firebase_data_connect/firebase_data_connect.dart';

class DefaultConnector {

  DefaultConnector({required this.dataConnect});
  static ConnectorConfig connectorConfig = ConnectorConfig(
    'northamerica-northeast2',
    'default',
    'artbeat-data-service',
  );
  static DefaultConnector get instance => DefaultConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,
        sdkType: CallerSDKType.generated,
      ),
    );

  FirebaseDataConnect dataConnect;
}
