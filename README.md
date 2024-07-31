
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
   import 'package:syncfusion_flutter_gauges/gauges.dart';
   import 'mqtt_service.dart';

   void main() {
     runApp(const MyApp());
   }

   class MyApp extends StatelessWidget {
     const MyApp({super.key});

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'Gauge MQTT App',
         theme: ThemeData(
           primarySwatch: Colors.blue,
         ),
         home: const GaugeScreen(),
       );
     }
   }

   class GaugeScreen extends StatefulWidget {
     const GaugeScreen({super.key});

     @override
     _GaugeScreenState createState() => _GaugeScreenState();
   }

   class _GaugeScreenState extends State<GaugeScreen> {
     late MqttService _mqttService;
     double _temperature = 0.0;

     @override
     void initState() {
       super.initState();
       _mqttService = MqttService('broker.emqx.io', '');
       _mqttService.getTemperatureStream().listen((temperature) {
         setState(() {
           _temperature = temperature;
         });
       });
     }

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Temperature Gauge'),
         ),
         body: Center(
           child: SfRadialGauge(
             axes: <RadialAxis>[
               RadialAxis(
                 minimum: -20,
                 maximum: 50,
                 ranges: <GaugeRange>[
                   GaugeRange(startValue: -20, endValue: 0, color: Colors.blue),
                   GaugeRange(startValue: 0, endValue: 25, color: Colors.green),
                   GaugeRange(startValue: 25, endValue: 50, color: Colors.red),
                 ],
                 pointers: <GaugePointer>[
                   NeedlePointer(value: _temperature),
                 ],
                 annotations: <GaugeAnnotation>[
                   GaugeAnnotation(
                     widget: Text(
                       '$_temperature°C',
                       style: const TextStyle(
                           fontSize: 20, fontWeight: FontWeight.bold),
                     ),
                     angle: 90,
                     positionFactor: 0.5,
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

### Paso 5: Redirigir Puertos con `adb`

1. **Abrir el Emulador** desde Android Studio (AVD Manager).

2. **Redirigir Puertos con `adb`**:
   - Abre una terminal y ejecuta el siguiente comando para redirigir los puertos necesarios:

     ```sh
     adb reverse tcp:1883 tcp:1883
     ```

### Paso 6: Ejecutar la Aplicación Flutter

1. **Ejecutar tu aplicación** en el emulador:

   ```sh
   flutter run
   ```

### Explicación Detallada del Código

#### `mqtt_service.dart`

```dart
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final MqttServerClient client;

  // Constructor de MqttService que inicializa el cliente MQTT
  MqttService(String server, String clientId)
      : client = MqttServerClient(server, '') {
    const sanitizedClientId = ''; // Asegura que el clientId sea válido

    client.logging(on: true);
    client.setProtocolV311(); // Configura el protocolo MQTT 3.1.1
    client.keepAlivePeriod = 20; // Configura el periodo de keep alive

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(sanitizedClientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage; // Asigna el mensaje de conexión
  }

  // Método que retorna un stream de datos de temperatura
  Stream<double> getTemperatureStream() async* {
    try {
      await client.connect(); // Intenta conectar al servidor MQTT
    } catch (e) {
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe("temperature/topic", MqttQos.atLeastOnce);

      // Escucha los mensajes entrantes y emite los valores de temperatura
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

#### `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'mqtt_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gauge MQTT App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GaugeScreen(),
    );
  }
}

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  _GaugeScreenState createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  late MqttService _mqttService;
  double _temperature = 0.0;

  @override
  void initState() {
    super.initState();
    _mqttService = MqttService('broker.emqx.io', ''); // Inicializa el servicio MQTT
    _mqttService.getTemperatureStream().listen((temperature) {
      setState(() {
        _temperature = temperature; // Actualiza la temperatura cuando llega un nuevo valor
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Gauge'),
      ),
      body: Center(
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: -20,
              maximum: 50,
              ranges: <GaugeRange>[
                GaugeRange(startValue: -20, endValue: 0, color: Colors.blue),
                GaugeRange(startValue: 0, endValue: 25, color: Colors.green),
                GaugeRange(startValue: 25, endValue: 50, color: Colors.red),
              ],
              pointers: <Gauge

Pointer>[
                NeedlePointer(value: _temperature),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    '$_temperature°C',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  angle: 90,
                  positionFactor: 0.5,
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

