import '../../../database/tdx_api_client.dart';
import 'transit_alert_adapters.dart';

class TransitAlertService {
  TransitAlertService({TdxApiClient? client})
      : client = client ?? TdxApiClient();

  final TdxApiClient client;

  List<TransitAlertAdapter> get adapters => <TransitAlertAdapter>[
        BusTransitAlertAdapter(client: client),
        MetroTransitAlertAdapter(client: client),
        ThsrTransitAlertAdapter(client: client),
        AviationTransitAlertAdapter(),
        YoubikeTransitAlertAdapter(),
        OtherTransitAlertAdapter(),
      ];
}
