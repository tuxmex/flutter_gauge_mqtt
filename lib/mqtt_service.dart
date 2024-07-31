import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final MqttServerClient client;

  MqttService(String server, String clientId)
      : client = MqttServerClient(server, '') {
    // Asegúrate de que el clientId sea válido
    const sanitizedClientId = '';

    client.logging(on: true);
    client.setProtocolV311();
    client.keepAlivePeriod = 20;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(sanitizedClientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;
  }

  Stream<double> getTemperatureStream() async* {
    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe("temperature/topic", MqttQos.atLeastOnce);

      await for (final c in client.updates!) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        yield double.tryParse(pt) ?? 0.0;
      }
    } else {
      client.disconnect();
    }
  }
}
