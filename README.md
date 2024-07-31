
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
import 'package:mqtt_client/mqtt_client.dart'; // Importa la biblioteca MQTT Client
import 'package:mqtt_client/mqtt_server_client.dart'; // Importa la biblioteca MQTT Server Client

class MqttService {
  final MqttServerClient client; // Declaración del cliente MQTT

  // Constructor de MqttService que inicializa el cliente MQTT
  MqttService(String server, String clientId)
      : client = MqttServerClient(server, '') {
    // Asegúrate de que el clientId sea válido
    const sanitizedClientId = '';

    client.logging(on: true); // Habilita el logging para el cliente MQTT
    client.setProtocolV311(); // Configura el protocolo MQTT 3.1.1
    client.keepAlivePeriod = 20; // Configura el periodo de keep alive en 20 segundos

    // Configuración del mensaje de conexión
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(sanitizedClientId) // Identificador del cliente
        .startClean() // Indica que el cliente debe comenzar con una sesión limpia
        .withWillQos(MqttQos.atLeastOnce); // Configura el QoS para el mensaje de "última voluntad"

    client.connectionMessage = connMessage; // Asigna el mensaje de conexión al cliente
  }

  // Método que retorna un stream de datos de temperatura
  Stream<double> getTemperatureStream() async* {
    try {
      // Intenta conectar al servidor MQTT
      await client.connect();
    } catch (e) {
      // Si la conexión falla, desconecta el cliente y retorna
      client.disconnect();
      return;
    }

    // Verifica si la conexión fue exitosa
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      // Se suscribe al tópico de temperatura con QoS 1
      client.subscribe("temperature/topic", MqttQos.atLeastOnce);

      // Escucha los mensajes entrantes y emite los valores de temperatura
      await for (final c in client.updates!) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage; // Obtiene el mensaje publicado
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message); // Convierte el payload a String
        yield double.tryParse(pt) ?? 0.0; // Convierte el payload a double y lo emite en el stream
      }
    } else {
      // Si la conexión no fue exitosa, desconecta el cliente
      client.disconnect();
    }
  }
}
```

### Explicación Detallada del Código con Comentarios

- **Importaciones**:
  - `mqtt_client.dart`: Biblioteca principal para manejar las conexiones MQTT.
  - `mqtt_server_client.dart`: Biblioteca para configurar el cliente MQTT que se conecta a un servidor.

- **Clase `MqttService`**:
  - `MqttServerClient client`: Variable que representa el cliente MQTT.

- **Constructor `MqttService`**:
  - `MqttService(String server, String clientId)`: Inicializa el cliente MQTT con el servidor especificado y un `clientId`.
  - `client = MqttServerClient(server, '')`: Crea una instancia del cliente MQTT.
  - `client.logging(on: true)`: Habilita el logging para el cliente MQTT.
  - `client.setProtocolV311()`: Configura el cliente para usar el protocolo MQTT 3.1.1.
  - `client.keepAlivePeriod = 20`: Configura el periodo de keep alive en 20 segundos.
  - `MqttConnectMessage()`: Configura el mensaje de conexión con el `clientId`, indicando que debe empezar con una sesión limpia y configurando el QoS del mensaje de "última voluntad".
  - `client.connectionMessage = connMessage`: Asigna el mensaje de conexión al cliente.

- **Método `getTemperatureStream`**:
  - `Stream<double> getTemperatureStream() async*`: Método asincrónico que retorna un stream de datos de temperatura.
  - `try { await client.connect(); } catch (e) { ... }`: Intenta conectar al servidor MQTT. Si la conexión falla, desconecta el cliente y retorna.
  - `if (client.connectionStatus?.state == MqttConnectionState.connected) { ... }`: Verifica si la conexión fue exitosa.
  - `client.subscribe("temperature/topic", MqttQos.atLeastOnce)`: Se suscribe al tópico de temperatura con QoS 1.
  - `await for (final c in client.updates!) { ... }`: Escucha los mensajes entrantes y emite los valores de temperatura.
  - `final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage`: Obtiene el mensaje publicado.
  - `final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message)`: Convierte el payload del mensaje a una cadena de texto.
  - `yield double.tryParse(pt) ?? 0.0`: Convierte la cadena de texto a un número de punto flotante (double) y lo emite en el stream.

Este archivo `mqtt_service.dart` maneja la conexión al servidor MQTT, la suscripción al tópico de temperatura y la emisión de los datos de temperatura como un stream de valores double. Los comentarios detallados deberían ayudarte a entender cómo funciona cada parte del código.



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

### Explicación Detallada del Código con Comentarios

- **Importaciones**:
  - `flutter/material.dart`: Biblioteca principal de Flutter para construir la interfaz de usuario.
  - `syncfusion_flutter_gauges/gauges.dart`: Biblioteca para crear el gauge.
  - `mqtt_service.dart`: Servicio MQTT personalizado para manejar la conexión y suscripción a los mensajes.

- **Función `main`**:
  - `runApp(const MyApp())`: Inicia la aplicación Flutter, usando el widget `MyApp` como raíz.

- **Clase `MyApp`**:
  - `StatelessWidget`: Define un widget sin estado.
  - `MaterialApp`: Configura la aplicación, incluyendo el tema y la pantalla principal (`GaugeScreen`).

- **Clase `GaugeScreen`**:
  - `StatefulWidget`: Define un widget con estado.
  - `createState`: Método que crea y retorna una instancia del estado asociado (`_GaugeScreenState`).

- **Clase `_GaugeScreenState`**:
  - `late MqttService _mqttService`: Declara una variable para el servicio MQTT.
  - `double _temperature = 0.0`: Declara una variable para almacenar la temperatura.

  - `initState`: Método que se llama cuando el widget se inserta en el árbol de widgets. Aquí es donde inicializamos el servicio MQTT y comenzamos a escuchar los datos de temperatura.
    - `MqttService('broker.emqx.io', '')`: Inicializa el servicio MQTT con el broker y un `clientId` vacío.
    - `listen((temperature) { ... })`: Escucha el stream de temperatura y actualiza el estado cuando llega un nuevo valor.

  - `build`: Método que construye la interfaz de usuario.
    - `Scaffold`: Estructura básica de la pantalla con una barra de aplicación (`AppBar`) y un cuerpo (`body`).
    - `SfRadialGauge`: Widget que muestra el gauge radial.
      - `RadialAxis`: Configuración del eje radial del gauge, incluyendo los valores mínimos y máximos, los rangos de colores, la aguja (`NeedlePointer`) y las anotaciones (`GaugeAnnotation`).

### Explicación Detallada de la Interfaz de Usuario

- **MyApp**: Configura el tema de la aplicación y establece `GaugeScreen` como la pantalla principal.
- **GaugeScreen**: Es un `StatefulWidget` que mantiene el estado de la temperatura y se suscribe al stream de datos del servicio MQTT.
- **_GaugeScreenState**: Inicializa el servicio MQTT y escucha los datos de temperatura. Actualiza la UI cuando se recibe un nuevo valor de temperatura.
- **SfRadialGauge**: Configura y muestra el gauge, incluyendo los rangos de color y el valor actual de la temperatura.

