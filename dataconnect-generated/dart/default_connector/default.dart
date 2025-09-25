library default_connector;

import 'package:firebase_data_connect/firebase_data_connect.dart';

class DefaultConnector {
  DefaultConnector({required this.dataConnect});

  DefaultConnector.instance()
    : this(
        dataConnect: FirebaseDataConnect.instanceFor(
          connectorConfig: connectorConfig,
          sdkType: CallerSDKType.generated,
        ),
      );

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'northamerica-northeast2',
    'default',
    'artbeat-data-service',
  );

  FirebaseDataConnect dataConnect;
}
