
### Paso 1: Crear el Proyecto Flutter

1. **Abrir una terminal** y ejecutar el siguiente comando para crear un nuevo proyecto Flutter:

   ```sh
   flutter create gauge_mqtt_app
   cd gauge_mqtt_app
   ```

2. **Abrir el proyecto** en tu editor de código favorito (por ejemplo, Android Studio o Visual Studio Code).

### Paso 2: Configurar las Dependencias

1. **Editar `pubspec.yaml`** para agregar las dependencias necesarias. Abre el archivo y añade las siguientes líneas bajo `dependencies`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     syncfusion_flutter_gauges: ^21.1.1  # Dependencia para el gauge
     mqtt_client: ^9.6.1  # Dependencia para MQTT
   ```

2. **Instalar las dependencias** ejecutando el siguiente comando en la terminal:

   ```sh
   flutter pub get
   ```

### Paso 3: Implementar el Servicio MQTT

1. **Crear el archivo `mqtt_service.dart`** en el directorio `lib` y agrega el siguiente código:

   ```dart
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
   ```

### Paso 4: Implementar la Interfaz de Usuario

1. **Actualizar `main.dart`** con el siguiente código:

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Importa la biblioteca para el gauge
import 'mqtt_service.dart'; // Importa el servicio MQTT

void main() {
  runApp(const MyApp()); // Llama a runApp para iniciar la aplicación
}

// MyApp es un widget Stateless que define la estructura general de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gauge MQTT App', // Título de la aplicación
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema principal de la aplicación
      ),
      home: const GaugeScreen(), // Define GaugeScreen como la pantalla principal
    );
  }
}

// GaugeScreen es un StatefulWidget que mostrará el gauge de temperatura
class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  _GaugeScreenState createState() => _GaugeScreenState(); // Crea el estado asociado a este widget
}

// _GaugeScreenState contiene el estado del widget GaugeScreen
class _GaugeScreenState extends State<GaugeScreen> {
  late MqttService _mqttService; // Declaración del servicio MQTT
  double _temperature = 0.0; // Variable para almacenar la temperatura actual

  @override
  void initState() {
    super.initState();
    // Inicializa el servicio MQTT con el broker y el clientId
    _mqttService = MqttService('broker.emqx.io', '');
    // Escucha el stream de temperatura y actualiza el estado cuando llegue un nuevo valor
    _mqttService.getTemperatureStream().listen((temperature) {
      setState(() {
        _temperature = temperature; // Actualiza la temperatura
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Gauge'), // Título de la barra de la aplicación
      ),
      body: Center(
        // Contenedor principal de la pantalla
        child: SfRadialGauge(
          // Widget para mostrar el gauge radial
          axes: <RadialAxis>[
            RadialAxis(
              // Configuración del eje radial
              minimum: -20, // Valor mínimo del gauge
              maximum: 50, // Valor máximo del gauge
              ranges: <GaugeRange>[
                // Definición de rangos de colores en el gauge
                GaugeRange(startValue: -20, endValue: 0, color: Colors.blue), // Rango azul para temperaturas frías
                GaugeRange(startValue: 0, endValue: 25, color: Colors.green), // Rango verde para temperaturas moderadas
                GaugeRange(startValue: 25, endValue: 50, color: Colors.red), // Rango rojo para temperaturas calientes
              ],
              pointers: <GaugePointer>[
                // Aguja del gauge que indica la temperatura actual
                NeedlePointer(value: _temperature),
              ],
              annotations: <GaugeAnnotation>[
                // Anotación que muestra el valor de la temperatura en el centro del gauge
                GaugeAnnotation(
                  widget: Text(
                    '$_temperature°C', // Muestra la temperatura con un formato de texto
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold), // Estilo del texto
                  ),
                  angle: 90, // Ángulo de la anotación
                  positionFactor: 0.5, // Posición de la anotación en el gauge
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

```

### Explicación Detallada de la Interfaz de Usuario

- **MyApp**: Configura el tema de la aplicación y establece `GaugeScreen` como la pantalla principal.
- **GaugeScreen**: Es un `StatefulWidget` que mantiene el estado de la temperatura y se suscribe al stream de datos del servicio MQTT.
- **_GaugeScreenState**: Inicializa el servicio MQTT y escucha los datos de temperatura. Actualiza la UI cuando se recibe un nuevo valor de temperatura.
- **SfRadialGauge**: Configura y muestra el gauge, incluyendo los rangos de color y el valor actual de la temperatura.

